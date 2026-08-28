module Presences
  class StreetHeartbeat
    WRITE_INTERVAL = 12.seconds

    def self.call(person:, device_token:)
      new(person:, device_token:).call
    end

    def initialize(person:, device_token:)
      @person = person
      @device_token = device_token
    end

    def call
      return unless @person && @device_token.present?

      now = Time.current
      @person.person_devices
        .where(device_token: @device_token)
        .where("last_seen_at IS NULL OR last_seen_at < ?", now - WRITE_INTERVAL)
        .update_all(last_seen_at: now)
    end
  end
end
