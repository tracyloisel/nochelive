module Presenters
  class Resolve
    DECISIONS = %w[grant refuse block].freeze

    def self.call(night:, claim:, decision:, holder_token:)
      new(night:, claim:, decision:, holder_token:).call
    end

    def initialize(night:, claim:, decision:, holder_token:)
      @night = night
      @claim = claim
      @decision = decision.to_s
      @holder_token = holder_token.to_s
    end

    def call
      raise People::Error.new(:missing, I18n.t("errors.people.claim_missing")) unless @claim
      unless DECISIONS.include?(@decision)
        raise People::Error.new(:missing, I18n.t("errors.people.claim_choice"))
      end

      if @decision == "grant"
        raise People::Error.new(:forbidden, I18n.t("errors.people.not_holder")) unless holder?
        return Presenters::Grant.call(claim: @claim)
      end

      ApplicationRecord.transaction do
        claim = PresenterClaim.lock.find(@claim.id)
        night = GameSession.lock.find(claim.game_session_id)
        raise People::Error.new(:forbidden, I18n.t("errors.people.not_holder")) unless night.presenter_held_by?(@holder_token)
        raise People::Error.new(:missing, I18n.t("errors.people.claim_dead")) unless claim.pending?

        if @decision == "block"
          night.presenter_blocks.find_or_create_by!(device_digest: claim.device_digest)
          claim.update!(status: "blocked", resolved_at: Time.current)
        else
          claim.update!(status: "refused", resolved_at: Time.current)
        end
      end

      Presenters::Broadcast.call(night: @claim.game_session, claim: @claim.reload)
      @claim
    end

    private

      def holder?
        @night.presenter_held_by?(@holder_token)
      end
  end
end
