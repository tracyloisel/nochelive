module Quizzes
  class DuelInvitationDecline
    class Expired < StandardError; end
    class Taken < StandardError; end

    def self.call(invitation:, person:)
      declined = ApplicationRecord.transaction do
        locked = DuelInvitation.lock.find(invitation.id)
        raise Expired if locked.expired?
        raise Taken unless locked.open?
        raise Taken unless locked.recipient_person_id == person.id

        now = Time.current
        locked.update!(status: "declined", declined_at: now, seen_at: locked.seen_at || now)
        locked
      end
      ViralTrack.call(
        name: "invite_declined",
        device_digest: "person:#{person.id}",
        invitation: declined,
        person:,
        source: "invitation",
        event_key: "invite-declined:#{declined.id}"
      )
      challenger = declined.challenger_person
      I18n.with_locale(Locale.i18n(challenger.locale)) do
        Turbo::StreamsChannel.broadcast_replace_to(
          [ challenger, :duel_campus ],
          target: "duel_invitation_receipt_#{declined.id}",
          partial: "street_challenges/receipt",
          locals: { invitation: declined, viewer: challenger }
        )
      end
      declined
    end
  end
end
