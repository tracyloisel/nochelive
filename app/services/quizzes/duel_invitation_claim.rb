module Quizzes
  class DuelInvitationClaim
    Result = Struct.new(:invitation, :duel, :created, keyword_init: true)
    class Expired < StandardError; end
    class Taken < StandardError; end

    def self.call(invitation:, person:, device_digest: nil)
      new(invitation:, person:, device_digest:).call
    end

    def initialize(invitation:, person:, device_digest:)
      @invitation = invitation
      @person = person
      @device_digest = device_digest
    end

    def call
      result = ApplicationRecord.transaction do
        lock_people!(@invitation)
        invitation = DuelInvitation.lock.find(@invitation.id)
        raise Expired if invitation.expired?
        if invitation.claimed?
          raise Taken unless invitation.claimed_by_person_id == @person.id
          next Result.new(invitation:, duel: invitation.street_duel, created: false)
        end
        raise Taken unless invitation.open?
        raise Taken if invitation.challenger_person_id == @person.id
        raise Taken if invitation.named? && invitation.recipient_person_id != @person.id

        duel = find_active_pair(invitation)
        created = false
        unless duel
          duel = build_duel(invitation)
          duel.save!
          created = true
        end
        now = Time.current
        invitation.update!(
          status: "claimed",
          claimed_by_person: @person,
          street_duel: duel,
          claimed_at: now,
          seen_at: invitation.seen_at || (now if invitation.named?)
        )
        Result.new(invitation:, duel:, created:)
      end
      track(result)
      DuelInvitationReceipt.call(
        invitation: result.invitation,
        state: :seen,
        person: @person,
        device_digest: @device_digest
      ) if result.invitation.named?
      result
    end

    private

      def lock_people!(invitation)
        Person.where(id: [ invitation.challenger_person_id, @person.id ].sort).order(:id).lock.load
      end

      def find_active_pair(invitation)
        low, high = [ invitation.challenger_person_id, @person.id ].sort
        scope = StreetDuel.active.where(pair_low_person_id: low, pair_high_person_id: high)
        scope.where(expires_at: ..Time.current).update_all(status: "expired", updated_at: Time.current)
        scope.not_expired.lock.first
      end

      def build_duel(invitation)
        run = invitation.challenger_run if invitation.challenger_run&.finished?

        StreetDuel.new(
          challenger_person: invitation.challenger_person,
          opponent_person: @person,
          challenger_run: run,
          challenger_score: run&.score || invitation.challenger_score,
          status: run || invitation.challenger_score ? "one_scored" : "active",
          accepted_at: Time.current,
          expires_at: 14.days.from_now,
          rematch_of: invitation.rematch_of_duel,
          origin_invitation: invitation
        )
      end

      def track(result)
        invitation = result.invitation
        ViralTrack.call(
          name: "invite_claimed",
          device_digest: @device_digest || "person:#{@person.id}",
          invitation:,
          duel: result.duel,
          person: @person,
          source: "invite",
          event_key: "invite-claimed:#{invitation.id}",
          properties: { channel: invitation.channel }
        )
        ViralTrack.call(
          name: "duel_activated",
          device_digest: @device_digest || "person:#{@person.id}",
          invitation:,
          duel: result.duel,
          person: @person,
          source: "invite",
          event_key: "duel-activated:#{result.duel.id}"
        )
      end
  end
end
