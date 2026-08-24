module Presenters
  class Grant
    def self.call(claim:)
      new(claim:).call
    end

    def initialize(claim:)
      @claim = claim
    end

    def call
      ApplicationRecord.transaction do
        claim = PresenterClaim.lock.find(@claim.id)
        return claim unless claim.pending?

        night = GameSession.lock.find(claim.game_session_id)
        claim.update!(status: "granted", resolved_at: Time.current)
        Presenters::Seat.call(night:, device_digest: claim.device_digest)
      end

      @claim.reload
      Presenters::Broadcast.call(night: @claim.game_session, claim: @claim)
      @claim
    end
  end
end
