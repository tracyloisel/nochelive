require "json"
require "set"
require "connection_pool"

module Presences
  # Ephemeral presence registry. Production state lives in Redis/Valkey; local
  # development and tests use the same API in memory. PostgreSQL is deliberately
  # not a fallback: an unavailable realtime store must never create DB churn.
  class Registry
    ACTIVE_WINDOW = 45.seconds
    ENTRY_TTL = 90.seconds
    NAMESPACE = "nochelive:presence:v1"

    Entry = Data.define(
      :connection_id, :person_id, :ward_id, :player_id, :night_id,
      :team_id, :role, :location
    ) do
      def platform_identity
        person_id ? "person:#{person_id}" : "player:#{player_id}"
      end

      def to_h
        members.to_h { |member| [ member, public_send(member) ] }
      end
    end

    Change = Data.define(:entry, :platform_changed, :night_changed)

    class << self
      def enter(connection_id:, person_id: nil, ward_id: nil, player_id: nil, night_id: nil,
        team_id: nil, role: nil, location: nil)
        entry = Entry.new(
          connection_id: connection_id.to_s,
          person_id: integer_or_nil(person_id),
          ward_id: integer_or_nil(ward_id),
          player_id: integer_or_nil(player_id),
          night_id: integer_or_nil(night_id),
          team_id: integer_or_nil(team_id),
          role: role&.to_s,
          location: location&.to_s
        )
        raise ArgumentError, "presence requires a person or player" if entry.person_id.nil? && entry.player_id.nil?

        platform_was_online = identity_online?(entry)
        night_was_online = entry.player_id && entry.night_id ? player_online?(entry.player_id, night_id: entry.night_id) : false
        write(entry)
        Change.new(entry:, platform_changed: !platform_was_online, night_changed: !!(entry.night_id && !night_was_online))
      end

      def touch(entry)
        unless connection_active?(entry)
          return enter(**entry.to_h)
        end

        write(entry)
        Change.new(entry:, platform_changed: false, night_changed: false)
      end

      def leave(entry)
        remove(entry)
        Change.new(
          entry:,
          platform_changed: !identity_online?(entry),
          night_changed: !!(entry.night_id && !player_online?(entry.player_id, night_id: entry.night_id))
        )
      end

      def live_count
        active_entries(index_key(:all)).map(&:platform_identity).uniq.size
      rescue Redis::BaseError => error
        report_store_error(error, :live_count)
        0
      end

      def person_online?(person_id)
        active_entries(index_key(:person, person_id)).any?
      rescue Redis::BaseError => error
        report_store_error(error, :person_online)
        false
      end

      def player_online?(player_id, night_id: nil)
        rows = active_entries(index_key(:player, player_id))
        night_id ? rows.any? { |entry| entry.night_id == night_id.to_i } : rows.any?
      rescue Redis::BaseError => error
        report_store_error(error, :player_online)
        false
      end

      def online_person_ids(ward_id: nil, among: nil)
        key = ward_id ? index_key(:ward, ward_id) : index_key(:all)
        ids = active_entries(key).filter_map(&:person_id).to_set
        ids &= Array(among).map(&:to_i).to_set if among
        ids
      rescue Redis::BaseError => error
        report_store_error(error, :online_people)
        Set.new
      end

      def online_player_ids(night_id:)
        active_entries(index_key(:night, night_id)).filter_map(&:player_id).to_set
      rescue Redis::BaseError => error
        report_store_error(error, :online_players)
        Set.new
      end

      def reset!
        if redis_enabled?
          with_redis do |redis|
            keys = redis.scan_each(match: "#{NAMESPACE}:*").to_a
            redis.del(*keys) if keys.any?
          end
        else
          memory_mutex.synchronize do
            memory_entries.clear
            memory_indexes.clear
          end
        end
      end

      private

        def connection_active?(entry)
          now = Time.current.to_f
          if redis_enabled?
            with_redis do |redis|
              score = redis.zscore(index_key(:all), entry.connection_id)
              score && score >= now
            end
          else
            memory_mutex.synchronize do
              memory_indexes[index_key(:all)][entry.connection_id].to_f >= now
            end
          end
        end

        def identity_online?(entry)
          entry.person_id ? person_online?(entry.person_id) : player_online?(entry.player_id)
        end

        def write(entry)
          expires_at = ACTIVE_WINDOW.from_now.to_f
          if redis_enabled?
            with_redis do |redis|
              redis.multi do |pipeline|
                pipeline.set(entry_key(entry.connection_id), JSON.generate(entry.to_h), ex: ENTRY_TTL.to_i)
                index_keys(entry).each { |key| pipeline.zadd(key, expires_at, entry.connection_id) }
              end
            end
          else
            memory_mutex.synchronize do
              memory_entries[entry.connection_id] = [ entry, expires_at ]
              index_keys(entry).each { |key| memory_indexes[key][entry.connection_id] = expires_at }
            end
          end
          entry
        end

        def remove(entry)
          if redis_enabled?
            with_redis do |redis|
              redis.multi do |pipeline|
                pipeline.del(entry_key(entry.connection_id))
                index_keys(entry).each { |key| pipeline.zrem(key, entry.connection_id) }
              end
            end
          else
            memory_mutex.synchronize do
              memory_entries.delete(entry.connection_id)
              index_keys(entry).each { |key| memory_indexes[key].delete(entry.connection_id) }
            end
          end
        end

        def active_entries(key)
          redis_enabled? ? redis_entries(key) : in_memory_entries(key)
        end

        def redis_entries(key)
          now = Time.current.to_f
          with_redis do |redis|
            redis.zremrangebyscore(key, "-inf", now)
            ids = redis.zrangebyscore(key, now, "+inf")
            return [] if ids.empty?

            payloads = redis.mget(*ids.map { |id| entry_key(id) })
            payloads.filter_map { |payload| deserialize(payload) }
          end
        end

        def in_memory_entries(key)
          now = Time.current.to_f
          memory_mutex.synchronize do
            index = memory_indexes[key]
            index.delete_if { |_id, expires_at| expires_at < now }
            index.keys.filter_map do |id|
              entry, expires_at = memory_entries[id]
              next if entry.nil? || expires_at < now

              entry
            end
          end
        end

        def deserialize(payload)
          return if payload.blank?

          attributes = JSON.parse(payload, symbolize_names: true)
          Entry.new(**attributes.slice(*Entry.members))
        rescue JSON::ParserError, ArgumentError
          nil
        end

        def index_keys(entry)
          keys = [ index_key(:all) ]
          keys << index_key(:person, entry.person_id) if entry.person_id
          keys << index_key(:ward, entry.ward_id) if entry.ward_id
          keys << index_key(:player, entry.player_id) if entry.player_id
          keys << index_key(:night, entry.night_id) if entry.night_id
          keys
        end

        def index_key(kind, id = nil)
          [ NAMESPACE, "index", kind, id ].compact.join(":")
        end

        def entry_key(connection_id)
          "#{NAMESPACE}:entry:#{connection_id}"
        end

        def redis_enabled?
          ENV["REDIS_URL"].present?
        end

        def with_redis(&block)
          redis_pool.with(&block)
        end

        def redis_pool
          @redis_pool ||= ConnectionPool.new(size: ENV.fetch("RAILS_MAX_THREADS", 10).to_i, timeout: 1) do
            Redis.new(
              url: ENV.fetch("REDIS_URL"),
              connect_timeout: 1,
              read_timeout: 1,
              write_timeout: 1,
              reconnect_attempts: 2
            )
          end
        end

        def memory_entries
          @memory_entries ||= {}
        end

        def memory_indexes
          @memory_indexes ||= Hash.new { |hash, key| hash[key] = {} }
        end

        def memory_mutex
          @memory_mutex ||= Mutex.new
        end

        def integer_or_nil(value)
          Integer(value, exception: false)
        end

        def report_store_error(error, operation)
          Rails.error.report(error, context: { component: "presence_registry", operation: })
        end
    end
  end
end
