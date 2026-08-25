module Nights
  class Broadcast
    def self.call(night:, pulse: nil)
      new(night, pulse: pulse).call
    end

    def initialize(night, pulse: nil)
      @night = night.reload
      @pulse = pulse
    end

    def call
      publish_pulse
      replace_play
      replace_watch
      replace_presenter
    end

    private

    def replace_play
      @night.players.includes(:team, team: :reward_grants).where(role: "participant").find_each do |player|
        I18n.with_locale(Locale.i18n(player.locale)) do
          Turbo::StreamsChannel.broadcast_replace_to(
            @night.player_stream(player),
            target: "night_play",
            partial: "play/frame",
            locals: { night: @night, team: player.team, player: player, pulse: @pulse }
          )
        end
      end
    end

    def replace_watch
      @night.players.where(role: "spectator").find_each do |player|
        I18n.with_locale(Locale.i18n(player.locale)) do
          Turbo::StreamsChannel.broadcast_replace_to(
            @night.player_stream(player),
            target: "night_watch",
            partial: "watch/frame",
            locals: { night: @night, pulse: @pulse }
          )
        end
      end

      I18n.with_locale(Locale.i18n(@night.presenter_locale)) do
        Turbo::StreamsChannel.broadcast_replace_to(
          @night.watch_stream,
          target: "night_watch",
          partial: "watch/frame",
          locals: { night: @night, pulse: @pulse }
        )
      end
    end

    def replace_presenter
      I18n.with_locale(Locale.i18n(@night.presenter_locale)) do
        Turbo::StreamsChannel.broadcast_replace_to(
          @night.presenter_stream,
          target: "night_presenter",
          partial: "presenter/consoles/frame",
          locals: { night: @night, pulse: @pulse }
        )
      end
    end

    def publish_pulse
      return if @pulse.blank?

      streams = [ [ @night.watch_stream, @night.presenter_locale ], [ @night.presenter_stream, @night.presenter_locale ] ]
      @night.players.where(role: "participant").find_each do |player|
        streams << [ @night.player_stream(player), player.locale ]
      end
      @night.players.where(role: "spectator").find_each do |player|
        streams << [ @night.player_stream(player), player.locale ]
      end

      streams.uniq.each do |stream, locale|
        I18n.with_locale(Locale.i18n(locale)) do
          Turbo::StreamsChannel.broadcast_append_to(
            stream,
            target: "live_pulses",
            partial: "shared/pulse",
            locals: { pulse: @pulse, round: @night.current_round_run }
          )
        end
      end
    end
  end
end
