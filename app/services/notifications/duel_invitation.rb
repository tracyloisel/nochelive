module Notifications
  class DuelInvitation
    def self.call(duel:)
      person = duel.opponent_person
      return [] unless person && duel.active? && !duel.expired?

      deliveries = Notifications::Enqueue.call(
        person:,
        kind: "duel_invitation",
        subject: duel,
        destination: Rails.application.routes.url_helpers.street_challenge_path(duel.token),
        dedupe_token: "duel-#{duel.id}-person-#{person.id}"
      )
      DuelReminderJob.set(wait_until: [ 24.hours.from_now, duel.expires_at - 1.hour ].min).perform_later(duel) if deliveries.any?
      deliveries
    end
  end
end
