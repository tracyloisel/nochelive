module Hubs
  class RamaEvents
    Card = Struct.new(
      :event_id, :kind, :state, :title, :summary,
      :cancellation_reason, :starts_at, :location_label, :path, :external,
      :still,
      keyword_init: true
    )

    DEFAULT_LIMIT = 12

    def self.call(ward:, at: Time.current, limit: DEFAULT_LIMIT)
      new(ward:, at:, limit:).call
    end

    def initialize(ward:, at:, limit:)
      @ward = ward
      @at = at
      @limit = limit
    end

    def call
      return [] unless @ward

      ward_event_cards
    end

    private

      def ward_event_cards
        WardEvent.visible_or_cancelled_at(@at)
          .where(ward_id: @ward.id)
          .chronological
          .limit(@limit)
          .map { |event| card_for(event) }
      end

      def card_for(event)
        cancelled = event.cancelled?
        Card.new(
          event_id: event.id,
          kind: event.kind.to_sym,
          state: event.status.to_sym,
          title: event.title,
          summary: event.summary,
          cancellation_reason: event.cancellation_reason,
          starts_at: event.starts_at.in_time_zone(@ward.time_zone),
          location_label: event.location_label,
          path: cancelled ? nil : event.destination,
          external: !cancelled && event.external_destination?,
          still: event.artwork_path
        )
      end
  end
end
