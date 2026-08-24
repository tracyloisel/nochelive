module Presenters
  class Seat
    def self.call(night:, device_token: nil, device_digest: nil, clear_pending: false)
      new(night:, device_token:, device_digest:, clear_pending:).call
    end

    def initialize(night:, device_token:, device_digest:, clear_pending:)
      @night = night
      @device_token = device_token
      @device_digest = device_digest
      @clear_pending = clear_pending
    end

    def call
      raise ArgumentError, "device required" if @device_digest.blank? && @device_token.blank?

      digest = @device_digest.presence || GameSession.digest_token(@device_token)

      dismissed = []
      ApplicationRecord.transaction do
        night = GameSession.lock.find(@night.id)
        night.update!(presenter_device_digest: digest)
        if @clear_pending
          night.presenter_claims.pending.find_each do |claim|
            claim.update!(status: "refused", resolved_at: Time.current)
            dismissed << claim
          end
        end
        @night = night
      end

      dismissed.each { |claim| Presenters::Broadcast.call(night: @night, claim: claim) }
      @night
    end
  end
end
