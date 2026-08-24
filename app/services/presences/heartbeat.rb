module Presences
  class Heartbeat
    def self.call(player:)
      new(player).call
    end

    def initialize(player)
      @player = player
    end

    def call
      @player.update_column(:last_seen_at, Time.current)
      night = @player.game_session
      snapshot = Snapshot.call(night: night)
      digest = [ snapshot.live, snapshot.room, snapshot.remote, snapshot.joined ] +
        snapshot.teams.flat_map { |row| [ row.team.id, row.joined, row.live ] }
      key = "presence/#{night.id}"
      previous = Rails.cache.read(key)
      Rails.cache.write(key, digest, expires_in: 2.minutes)
      Nights::BroadcastPresence.call(night: night) unless previous == digest
      snapshot
    end
  end
end
