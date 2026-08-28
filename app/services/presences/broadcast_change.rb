module Presences
  class BroadcastChange
    def self.call(change)
      return unless change

      new(change).call
    end

    def initialize(change)
      @change = change
    end

    def call
      broadcast_night if @change.night_changed
      broadcast_platform if @change.platform_changed
    end

    private

      def broadcast_night
        night = GameSession.find_by(id: @change.entry.night_id)
        Nights::BroadcastPresence.call(night:) if night
      end

      def broadcast_platform
        pulse = Platform::Pulse.call
        I18n.available_locales.each do |locale|
          I18n.with_locale(locale) do
            Turbo::StreamsChannel.broadcast_replace_to(
              [ :street_presence, locale ],
              target: "street_pulse",
              partial: "street_hub/pulse_frame",
              locals: { pulse: }
            )
          end
        end
      end
  end
end
