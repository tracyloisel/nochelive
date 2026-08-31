module Nights
  class Broadcast
    def self.call(night:, event: nil, **)
      new(night:, event:).call
    end

    def initialize(night:, event:)
      @night = night.reload
      @event = event
    end

    def call
      projection = Nights::Projection.call(night: @night)
      latest_event = @event || projection.events.first
      Locale::AVAILABLE.each do |locale|
        I18n.with_locale(Locale.i18n(locale)) do
          if @event
            Turbo::StreamsChannel.broadcast_prepend_to(
              @night.locale_stream(locale),
              target: "live_events",
              partial: "nights/event",
              locals: { event: @event }
            )
          end
          Turbo::StreamsChannel.broadcast_replace_to(
            @night.locale_stream(locale),
            target: "live_event_tile",
            partial: "nights/live_tile",
            locals: { night: @night, event: latest_event }
          )
          Turbo::StreamsChannel.broadcast_replace_to(
            @night.locale_stream(locale),
            target: "night_projection",
            partial: "nights/projection",
            locals: { night: @night, projection: }
          )
        end
      end
    end
  end
end
