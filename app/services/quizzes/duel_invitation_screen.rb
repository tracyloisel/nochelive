module Quizzes
  class DuelInvitationScreen
    Result = Struct.new(
      :invitation, :state, :challenger, :score, :named, :rematch, :duel,
      keyword_init: true
    )

    def self.call(token:, person: nil, source: nil, device_digest: nil)
      new(token:, person:, source:, device_digest:).call
    end

    def initialize(token:, person:, source:, device_digest:)
      @token = token.to_s
      @person = person
      @source = source
      @device_digest = device_digest
    end

    def call
      invitation = DuelInvitation.find_by_token(@token)
      return unless invitation

      state = state_for(invitation)
      ViralTrack.call(
        name: "invite_link_rendered",
        device_digest: @device_digest,
        invitation:,
        person: @person,
        source: @source,
        properties: { state: }
      ) if @device_digest.present?
      Result.new(
        invitation:,
        state:,
        challenger: invitation.challenger_person,
        score: invitation.challenger_score,
        named: invitation.named?,
        rematch: invitation.rematch?,
        duel: invitation.street_duel
      )
    end

    private

      def state_for(invitation)
        return :claimed if invitation.claimed?
        return :declined if invitation.declined?
        return :revoked if invitation.revoked?
        return :expired if invitation.expired?
        return :other_recipient if invitation.named? && @person && invitation.recipient_person_id != @person.id

        :available
      end
  end
end
