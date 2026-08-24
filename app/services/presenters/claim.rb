module Presenters
  class Claim
    def self.call(night:, device_token:, name:)
      new(night:, device_token:, name:).call
    end

    def initialize(night:, device_token:, name:)
      @night = night
      @device_token = device_token.to_s
      @name = (name.to_s.strip.presence || "Alguien")[0, 40]
    end

    def call
      raise People::Error.new(:missing, "Falta el teléfono.") if @device_token.blank?

      Presenters::Expire.call(claim: @night.pending_presenter_claim)
      @night.reload

      claim = nil
      ApplicationRecord.transaction do
        night = GameSession.lock.find(@night.id)
        digest = GameSession.digest_token(@device_token)

        if night.presenter_blocks.exists?(device_digest: digest)
          raise People::Error.new(:blocked, "El presentador no te deja llevar esta noche.")
        end

        if night.presenter_device_digest.blank? || night.presenter_held_by?(@device_token)
          Presenters::Seat.call(night:, device_digest: digest)
          return :seated
        end

        mine = night.presenter_claims.pending.find_by(device_digest: digest)
        return mine if mine

        if night.presenter_claims.pending.exists?
          raise People::Error.new(:busy, "Ya hay alguien pidiendo la mesa. Espera un minuto.")
        end

        claim = night.presenter_claims.create!(
          device_digest: digest,
          name: @name,
          status: "pending",
          expires_at: PresenterClaim::TIMEOUT.seconds.from_now
        )
      end

      PresenterClaimExpiryJob.set(wait: PresenterClaim::TIMEOUT.seconds).perform_later(claim.id)
      Presenters::Broadcast.call(night: @night, claim: claim)
      claim
    end
  end
end
