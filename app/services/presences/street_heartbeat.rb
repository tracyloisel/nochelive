module Presences
  class StreetHeartbeat
    def self.call(person:, device_token:)
      new(person:, device_token:).call
    end

    def initialize(person:, device_token:)
      @person = person
      @device_token = device_token
    end

    def call
      return unless @person && @device_token.present?

      row = @person.person_devices.find_by(device_token: @device_token)
      return unless row

      row.update_column(:last_seen_at, Time.current)
      row
    end
  end
end
