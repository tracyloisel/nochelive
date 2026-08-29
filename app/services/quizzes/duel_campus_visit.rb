module Quizzes
  class DuelCampusVisit
    def self.call(person:, device_digest:, at: Time.current)
      new(person:, device_digest:, at:).call
    end

    def initialize(person:, device_digest:, at:)
      @person = person
      @device_digest = device_digest
      @at = at
    end

    def call
      ViralTrack.call(
        name: "duel_campus_viewed",
        device_digest: @device_digest,
        person: @person,
        source: "campus",
        event_key: "duel-campus-viewed:#{@person.id}:#{@at.to_date.iso8601}"
      )
      mature_pairs.each do |duel|
        other = duel.other_person_for(@person)
        ViralTrack.call(
          name: "pair_returned_d7",
          device_digest: @device_digest,
          duel:,
          person: @person,
          source: "campus",
          event_key: "pair-returned-d7:#{@person.id}:#{other.id}",
          properties: { role: duel.role_for(@person) }
        )
      end
    end

    private

      def mature_pairs
        StreetDuel
          .where("challenger_person_id = :id OR opponent_person_id = :id", id: @person.id)
          .where(accepted_at: ..(@at - 7.days))
          .where.not(status: "archived")
          .includes(:challenger_person, :opponent_person)
          .order(accepted_at: :asc, id: :asc)
          .to_a
          .uniq { |duel| duel.other_person_for(@person).id }
      end
  end
end
