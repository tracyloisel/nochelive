module Nights
  class BroadcastPresence
    def self.call(night:)
      new(night).call
    end

    def initialize(night)
      @night = night.reload
    end

    def call
      @night.players.where(role: "participant").includes(:team).find_each do |player|
        Turbo::StreamsChannel.broadcast_replace_to(
          @night.player_stream(player),
          target: "night_presence",
          partial: "shared/presence",
          locals: { night: @night, team: player.team, compact: player.team.present?, variant: "stage" }
        )
      end

      Turbo::StreamsChannel.broadcast_replace_to(
        @night.watch_stream,
        target: "night_presence",
        partial: "shared/presence",
        locals: { night: @night, team: nil, compact: false }
      )

      Turbo::StreamsChannel.broadcast_replace_to(
        @night.presenter_stream,
        target: "night_presence",
        partial: "shared/presence",
        locals: { night: @night, team: nil, compact: false, variant: "stage" }
      )
    end
  end
end
