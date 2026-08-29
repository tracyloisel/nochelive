class DuelReminderJob < ApplicationJob
  queue_as :notifications_transactional
  discard_on ActiveJob::DeserializationError

  def perform(invitation)
    invitation.reload
    return unless invitation.named? && invitation.available?
    return if Notifications::DuelResults.live?(invitation.recipient_person)

    Notifications::Enqueue.call(
      person: invitation.recipient_person,
      kind: "duel_reminder",
      subject: invitation,
      destination: Rails.application.routes.url_helpers.street_challenge_path(invitation.public_token),
      dedupe_token: "duel-invitation-#{invitation.id}-person-#{invitation.recipient_person_id}"
    )
  end
end
