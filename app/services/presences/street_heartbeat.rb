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

      Registry.enter(
        connection_id: "legacy:street:#{@person.id}:#{GameSession.digest_token(@device_token).first(16)}",
        person_id: @person.id,
        ward_id: @person.ward_id,
        role: "street"
      ).entry
    rescue Redis::BaseError => error
      Rails.error.report(error, context: { component: "legacy_presence", scope: "street" })
      nil
    end
  end
end
