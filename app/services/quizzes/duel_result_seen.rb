module Quizzes
  class DuelResultSeen
    def self.call(duel:, person:, device_digest: nil)
      return false unless duel.resolved? && duel.includes_person?(person)

      attribute = duel.role_for(person) == :challenger ? :challenger_result_seen_at : :opponent_result_seen_at
      changed = false
      ApplicationRecord.transaction do
        locked = StreetDuel.lock.find(duel.id)
        if locked.public_send(attribute).nil?
          locked.update_columns(attribute => Time.current, updated_at: Time.current)
          changed = true
        end
      end
      if changed
        ViralTrack.call(
          name: "duel_result_viewed",
          device_digest: device_digest || "person:#{person.id}",
          duel:,
          person:,
          source: "campus",
          event_key: "duel-result-viewed:#{duel.id}:#{person.id}"
        )
      end
      true
    end
  end
end
