module Notifications
  class DuelInvitation
    def self.call(invitation:)
      person = invitation.recipient_person
      return [] unless person && invitation.available?

      deliveries = Notifications::Enqueue.call(
        person:,
        kind: "duel_invitation",
        subject: invitation,
        destination: Rails.application.routes.url_helpers.street_challenge_path(invitation.public_token),
        dedupe_token: "duel-invitation-#{invitation.id}-person-#{person.id}"
      )
      DuelReminderJob.set(wait_until: [ 24.hours.from_now, invitation.expires_at - 1.hour ].min)
        .perform_later(invitation) if deliveries.any?
      deliveries
    end
  end
end
