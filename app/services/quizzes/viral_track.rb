module Quizzes
  class ViralTrack
    ALLOWED_PROPERTIES = %w[pack_id channel role outcome].freeze

    def self.call(name:, device_digest:, duel: nil, person: nil, source: nil, properties: {})
      return unless ViralEvent::NAMES.include?(name.to_s)
      return if device_digest.blank?

      ViralEvent.create!(
        name: name.to_s,
        device_digest:,
        street_duel: duel,
        person:,
        source: source.to_s.presence&.first(40),
        properties: properties.to_h.stringify_keys.slice(*ALLOWED_PROPERTIES)
      )
    end
  end
end
