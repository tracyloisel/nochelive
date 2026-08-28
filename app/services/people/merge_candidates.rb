module People
  class MergeCandidates
    Card = Struct.new(:person, :score, :on_device, :claimable, keyword_init: true)

    def self.call(person:, device_token:)
      return [] unless person&.ward

      people = person.ward.people.named(person.given_name).where.not(id: person.id).order(:created_at, :id).to_a
      scores = Quizzes::Leaderboard.pack_best_totals(ward: person.ward)
      device_ids = PersonDevice.where(person: people, device_token: device_token).pluck(:person_id).to_set

      people.map do |candidate|
        Card.new(
          person: candidate,
          score: scores[candidate.id].to_i,
          on_device: device_ids.include?(candidate.id),
          claimable: device_ids.include?(candidate.id) || candidate.favorite_year.present?
        )
      end
    end
  end
end
