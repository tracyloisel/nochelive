# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Wards
  class QueryLocator
    MAPS = "https://maps.churchofjesuschrist.org/api/maps-proxy/v2"
    USER_AGENT = "NocheLive/1.0 (ward search; +https://github.com/tracyloisel/nochelive)"
    ORIGIN = "https://maps.churchofjesuschrist.org"
    LIMIT = 8
    TIMEOUT = 5
    CACHE_TTL = 10.minutes

    class << self
      attr_accessor :transport, :forced_hits, :forced_details, :forced_near
    end

    def self.call(query:)
      return Array(forced_hits) unless forced_hits.nil?

      new(query:).search
    end

    def self.near(latitude:, longitude:)
      return Array(forced_near) unless forced_near.nil?

      new(query: "").near(latitude, longitude)
    end

    def self.details(church_unit_id:)
      return forced_details unless forced_details.nil?

      new(query: "").detail(church_unit_id)
    end

    def self.attrs_from(row)
      new(query: "").attrs_from(row)
    end

    def initialize(query:)
      @query = query.to_s.strip
    end

    def search
      return [] if @query.length < 2

      return fetch_hits if Rails.env.test?

      Rails.cache.fetch([ "locator", @query.downcase ], expires_in: CACHE_TTL) { fetch_hits }
    rescue StandardError
      []
    end

    def near(latitude, longitude)
      lat = latitude.to_f
      lng = longitude.to_f
      return [] unless lat.abs <= 90 && lng.abs <= 180

      body = maps_get("/locations/identify", layers: "MEETINGHOUSE", filters: "", associated: "WARDS",
        coordinates: "#{lng.round(5)},#{lat.round(5)}", nearest: 1)
      as_list(JSON.parse(body)).flat_map { |row| units_from(row) }.filter_map { |row| attrs_from(row) }.first(1)
    rescue StandardError
      []
    end

    def detail(church_unit_id)
      id = church_unit_id.to_s.sub(/\AWARD:/i, "").strip
      return if id.blank?

      attrs_from(fetch_units([ id ]).first)
    rescue StandardError
      nil
    end

    def attrs_from(row)
      return unless row.is_a?(Hash)
      return unless row["type"].to_s.upcase == "WARD"

      kind_code = row.dig("organizationType", "code").to_s.upcase
      kind = kind_code == "BRANCH" ? "branch" : "ward"
      coords = Array(row["coordinates"])
      address = row["address"] || {}
      parent = row["parent"] || {}
      facility = row["facility"] || {}
      id = row.dig("identifiers", "unitNumber").presence
      name = (row["nameDisplay"] || row["name"]).to_s.strip.gsub(/\s+/, " ")
      return if id.blank? || name.blank?

      {
        church_unit_id: id.to_s,
        name: name.first(Ward::NAME_MAX),
        unit_kind: kind,
        chapel_name: title_place(facility["nameDisplay"] || facility["name"])&.first(80),
        chapel_address: address["street1"].to_s.strip.gsub(/\s+/, " ").first(80).presence,
        city: title_place(address["city"])&.first(80),
        postal_code: address["postalCode"].to_s.strip.first(80).presence,
        country_code: address["countryCode2"].to_s.upcase.presence,
        country_name: address["country"].to_s.strip.first(80).presence,
        stake_name: (parent["nameDisplay"] || parent["name"]).to_s.strip.first(80).presence,
        latitude: coords[1],
        longitude: coords[0]
      }
    end

    private

      def fetch_hits
        body = maps_get("/locations/search", query: @query, layers: "MEETINGHOUSE,WARDS")
        as_list(JSON.parse(body)).filter_map { |row| attrs_from(row) }.first(LIMIT)
      end

      def fetch_units(ids)
        joined = ids.map { |id| "WARD:#{id}" }.join(",")
        as_list(JSON.parse(maps_get("/locations", ids: joined)))
      end

      def units_from(row)
        kids = Array(row["associated"])
        kids.any? ? kids : [ row ]
      end

      def as_list(parsed)
        case parsed
        when Array then parsed
        when Hash
          if parsed["id"] || parsed["identifiers"] || parsed["associated"]
            [ parsed ]
          else
            Array(parsed["locations"] || parsed["features"] || [])
          end
        else
          []
        end
      end

      def title_place(value)
        raw = value.to_s.strip
        return if raw.blank?
        return raw.titleize if raw.match?(/\A[\p{Lu}0-9\s.'-]+\z/)

        raw
      end

      def maps_get(path, params)
        http_get("#{MAPS}#{path}", params, origin: true)
      end

      def http_get(url, params, origin: false)
        return self.class.transport.call(url, params) if self.class.transport
        return "[]" if Rails.env.test?

        uri = URI(url)
        uri.query = URI.encode_www_form(params)
        Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
          req = Net::HTTP::Get.new(uri)
          req["User-Agent"] = USER_AGENT
          req["Accept"] = "application/json"
          if origin
            req["Origin"] = ORIGIN
            req["Referer"] = "#{ORIGIN}/search"
          end
          res = http.request(req)
          raise "Locator HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)

          res.body
        end
      end
  end
end
