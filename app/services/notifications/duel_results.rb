module Notifications
  class DuelResults
    def self.call(duel:)
      return [] unless duel.resolved?

      [ duel.challenger_person, duel.opponent_person ].compact.flat_map do |person|
        next [] if live?(person)

        Notifications::Enqueue.call(
          person:,
          kind: "duel_result",
          subject: duel,
          destination: Rails.application.routes.url_helpers.street_challenge_path(duel.token),
          dedupe_token: "duel-#{duel.id}-person-#{person.id}"
        )
      end
    end

    def self.live?(person)
      Presences::Registry.person_online?(person.id)
    end
  end
end
