module Quizzes
  class DuelInvitationCreate
    Result = Struct.new(:invitation, :token, :share_url, :duel, :reused, keyword_init: true)

    class Denied < StandardError
      attr_reader :code

      def initialize(code)
        @code = code.to_sym
        super(code.to_s)
      end
    end

    MAX_OPEN_OUTGOING = 12
    MAX_NAMED_PER_DAY = 4

    def self.call(challenger_person:, recipient_person: nil, run: nil, rematch_of_duel: nil,
      source: nil, channel: nil, url_helpers: Rails.application.routes.url_helpers)
      new(
        challenger_person:, recipient_person:, run:, rematch_of_duel:,
        source:, channel:, url_helpers:
      ).call
    end

    def initialize(challenger_person:, recipient_person:, run:, rematch_of_duel:, source:, channel:, url_helpers:)
      @challenger = challenger_person
      @recipient = recipient_person
      @run = run
      @rematch = rematch_of_duel
      @source = source.to_s.presence&.first(40)
      @channel = channel.to_s.presence&.first(40) || (@recipient ? "noche" : "link")
      @url_helpers = url_helpers
    end

    def call
      created = false
      result = ApplicationRecord.transaction do
        lock_people!
        validate_identity!
        if (duel = active_duel)
          Result.new(duel:, reused: true)
        elsif (invitation = reusable_invitation)
          token = invitation.public_token
          Result.new(invitation:, token:, share_url: path_for(token), reused: true)
        else
          validate_creation!
          invitation = DuelInvitation.create!(
            challenger_person: @challenger,
            recipient_person: @recipient,
            challenger_run: @run,
            challenger_score: @run&.score,
            rematch_of_duel: @rematch,
            acquisition_parent_invitation: acquisition_parent,
            token_digest: SecureRandom.hex(32),
            status: "open",
            source: @source,
            channel: @channel,
            expires_at: 7.days.from_now
          )
          token = invitation.refresh_public_token!
          created = true
          Result.new(invitation:, token:, share_url: path_for(token), reused: false)
        end
      end
      return result unless created

      invitation = result.invitation
      ViralTrack.call(
        name: "duel_invitation_created",
        device_digest: @run&.device_digest || "person:#{@challenger.id}",
        invitation:,
        person: @challenger,
        source: @source,
        event_key: "duel-invitation-created:#{invitation.id}",
        properties: { channel: @channel, generation: acquisition_generation(invitation) }
      )
      if invitation.acquisition_parent_invitation_id
        ViralTrack.call(
          name: "invitee_first_outbound_invite",
          device_digest: @run&.device_digest || "person:#{@challenger.id}",
          invitation:,
          person: @challenger,
          source: @source,
          event_key: "invitee-first-outbound:#{@challenger.id}",
          properties: { channel: @channel }
        )
      end
      DuelInvitationNotify.call(invitation:) if @recipient
      result
    end

    private

      def lock_people!
        Person.where(id: [ @challenger.id, @recipient&.id ].compact.sort).order(:id).lock.load
      end

      def validate_identity!
        raise Denied, :self if @recipient&.id == @challenger.id
        if @recipient && !StakeScope.allowed?(challenger_ward: @challenger.ward, opponent_ward: @recipient.ward)
          raise Denied, :scope
        end
        if @run && (!@run.finished? || @run.person_id != @challenger.id)
          raise Denied, :score
        end
        if @rematch
          raise Denied, :rematch unless @rematch.resolved? && @recipient
          pair = [ @rematch.challenger_person_id, @rematch.opponent_person_id ].sort
          raise Denied, :rematch unless pair == [ @challenger.id, @recipient.id ].sort
        end
      end

      def validate_creation!
        if @recipient && DuelInvitation.open_state.not_expired.exists?(
          challenger_person: @recipient,
          recipient_person: @challenger
        )
          raise Denied, :incoming
        end
        open_count = DuelInvitation.open_state.not_expired.where(challenger_person: @challenger).count
        raise Denied, :rate_limited if open_count >= MAX_OPEN_OUTGOING
        return unless @recipient

        recent_count = DuelInvitation.where(challenger_person: @challenger, recipient_person: @recipient)
          .where(created_at: 1.day.ago..)
          .count
        raise Denied, :rate_limited if recent_count >= MAX_NAMED_PER_DAY
      end

      def active_duel
        return unless @recipient

        scope = active_pair_scope
        scope.where(expires_at: ..Time.current).update_all(status: "expired", updated_at: Time.current)
        scope.not_expired.first
      end

      def active_pair_scope
        low, high = [ @challenger.id, @recipient.id ].sort
        StreetDuel.active.where(pair_low_person_id: low, pair_high_person_id: high)
      end

      def reusable_invitation
        scope = DuelInvitation.open_state.not_expired.where(challenger_person: @challenger)
        if @recipient
          scope = scope.where(recipient_person: @recipient)
          scope = @rematch ? scope.where(rematch_of_duel: @rematch) : scope.where(rematch_of_duel_id: nil)
        else
          scope = scope.where(
            recipient_person_id: nil,
            challenger_run: @run,
            rematch_of_duel_id: nil,
            source: @source
          )
        end
        scope.order(:id).first
      end

      def acquisition_parent
        DuelInvitation.where(status: "claimed", claimed_by_person: @challenger)
          .where.not(claimed_at: nil)
          .order(claimed_at: :desc, id: :desc)
          .first
      end

      def acquisition_generation(invitation)
        generation = 0
        node = invitation.acquisition_parent_invitation
        while node && generation < 20
          generation += 1
          node = node.acquisition_parent_invitation
        end
        generation
      end

      def path_for(token)
        @url_helpers.street_challenge_path(token)
      end
  end
end
