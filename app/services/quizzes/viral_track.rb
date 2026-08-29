module Quizzes
  class ViralTrack
    ALLOWED_PROPERTIES = %w[
      pack_id channel role outcome state count resolved_count generation locale platform variant
    ].freeze

    def self.call(name:, device_digest:, duel: nil, invitation: nil, person: nil, source: nil, event_key: nil, properties: {})
      return unless ViralEvent::NAMES.include?(name.to_s)
      return if device_digest.blank?

      attributes = {
        name: name.to_s,
        device_digest:,
        street_duel: duel,
        duel_invitation: invitation,
        person:,
        source: source.to_s.presence&.first(40),
        properties: properties.to_h.stringify_keys.slice(*ALLOWED_PROPERTIES)
      }
      key = event_key.to_s.presence
      return ViralEvent.create!(attributes) unless key

      ViralEvent.find_or_create_by!(event_key: key) do |event|
        event.assign_attributes(attributes)
      end
    rescue ActiveRecord::RecordNotUnique
      ViralEvent.find_by(event_key: key) if key
    end
  end
end
