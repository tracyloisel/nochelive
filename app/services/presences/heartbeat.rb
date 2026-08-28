module Presences
  class Heartbeat
    def self.call(player:)
      new(player).call
    end

    def initialize(player)
      @player = player
    end

    def call
      night = @player.game_session
      change = Registry.enter(
        connection_id: "legacy:night:#{@player.id}",
        person_id: @player.person_id,
        ward_id: night.ward_id,
        player_id: @player.id,
        night_id: night.id,
        team_id: @player.team&.id,
        role: @player.role,
        location: @player.location
      )
      BroadcastChange.call(change)
      Snapshot.call(night:)
    rescue Redis::BaseError => error
      Rails.error.report(error, context: { component: "legacy_presence", scope: "night" })
      Snapshot.call(night: @player.game_session)
    end
  end
end
