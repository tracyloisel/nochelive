class DuelReminderJob < ApplicationJob
  queue_as :notifications_transactional
  discard_on ActiveJob::DeserializationError

  def perform(duel)
    duel.reload
    return unless duel.active? && !duel.expired? && duel.opponent_person
    return if Notifications::DuelResults.live?(duel.opponent_person)

    Notifications::Enqueue.call(
      person: duel.opponent_person,
      kind: "duel_reminder",
      subject: duel,
      destination: Rails.application.routes.url_helpers.street_challenge_path(duel.token),
      dedupe_token: "duel-#{duel.id}-person-#{duel.opponent_person_id}"
    )
  end
end
