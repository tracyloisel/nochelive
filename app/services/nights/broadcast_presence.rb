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
        I18n.with_locale(Locale.i18n(player.locale)) do
          Turbo::StreamsChannel.broadcast_replace_to(
            @night.player_stream(player),
            target: "night_presence",
            partial: "shared/presence",
            locals: { night: @night, team: player.team, compact: player.team.present?, variant: "stage" }
          )
        end
      end

      @night.players.where(role: "spectator").find_each do |player|
        I18n.with_locale(Locale.i18n(player.locale)) do
          Turbo::StreamsChannel.broadcast_replace_to(
            @night.player_stream(player),
            target: "night_presence",
            partial: "shared/presence",
            locals: { night: @night, team: nil, compact: false }
          )
        end
      end

      I18n.with_locale(Locale.i18n(@night.presenter_locale)) do
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
end
