module ScriptureCircles
  # Sends a content-free Turbo refresh to Circle readers in one rama. Each
  # browser then re-renders its own index from the current URL and session, so
  # anonymous authorship and the "mine" filter are never shared in a broadcast.
  class RamaRefresh
    STREAM = :scripture_circle
    TARGET = "circle_live_feed".freeze

    def self.call(ward:)
      return unless ward&.scripture_circle_readable?

      Turbo::StreamsChannel.broadcast_action_to(
        ward, STREAM, action: :circle_refresh, target: TARGET, render: false
      )
    rescue StandardError => error
      Rails.logger.warn("scripture circle refresh broadcast failed: #{error.class}: #{error.message}")
      nil
    end
  end
end
