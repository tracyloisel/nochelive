module Quizzes
  class DuelInvitationReceipt
    STATES = %i[delivered seen human_opened share_handoff].freeze

    def self.call(invitation:, state:, person: nil, device_digest: nil, source: nil, channel: nil)
      new(invitation:, state:, person:, device_digest:, source:, channel:).call
    end

    def initialize(invitation:, state:, person:, device_digest:, source:, channel:)
      @invitation = invitation
      @state = state.to_sym
      @person = person
      @device_digest = device_digest
      @source = source
      @channel = channel
    end

    def call
      return false unless STATES.include?(@state)
      return false unless permitted?

      changed = false
      invitation = ApplicationRecord.transaction do
        locked = DuelInvitation.lock.find(@invitation.id)
        now = Time.current
        attribute = attribute_for
        if locked.public_send(attribute).nil?
          locked.update_columns(attribute => now, updated_at: now)
          changed = true
        end
        locked.reload
      end
      track(invitation) if changed
      broadcast(invitation) if changed
      true
    end

    private

      def permitted?
        case @state
        when :delivered, :seen
          @invitation.named? && @person&.id == @invitation.recipient_person_id
        when :human_opened
          @invitation.external? && @person&.id != @invitation.challenger_person_id
        when :share_handoff
          @person&.id == @invitation.challenger_person_id
        end
      end

      def attribute_for
        {
          delivered: :delivered_at,
          seen: :seen_at,
          human_opened: :human_opened_at,
          share_handoff: :share_handoff_at
        }.fetch(@state)
      end

      def track(invitation)
        name = {
          delivered: "named_invite_delivered",
          seen: "named_invite_seen",
          human_opened: "invite_human_opened",
          share_handoff: "invite_share_handoff"
        }.fetch(@state)
        ViralTrack.call(
          name:,
          device_digest: @device_digest || "invitation:#{invitation.id}",
          invitation:,
          person: @person,
          source: @source,
          event_key: "#{name}:#{invitation.id}",
          properties: { channel: @channel || invitation.channel }
        )
      end

      def broadcast(invitation)
        challenger = invitation.challenger_person
        I18n.with_locale(Locale.i18n(challenger.locale)) do
          Turbo::StreamsChannel.broadcast_replace_to(
            [ challenger, :duel_campus ],
            target: "duel_invitation_receipt_#{invitation.id}",
            partial: "street_challenges/receipt",
            locals: { invitation:, viewer: challenger }
          )
        end
      end
  end
end
