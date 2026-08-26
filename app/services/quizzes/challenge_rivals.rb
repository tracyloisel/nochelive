module Quizzes
  class ChallengeRivals
    LIMIT = 8
    Row = Struct.new(:rank, :person, :score, :answered, :live, :state, keyword_init: true)

    def self.call(ward:, person:, pack_id:, q: nil, limit: LIMIT)
      new(ward:, person:, pack_id:, q:, limit:).call
    end

    def initialize(ward:, person:, pack_id:, q: nil, limit: LIMIT)
      @ward = ward
      @person = person
      @pack_id = pack_id.to_s.presence
      @q = q.to_s.strip
      @limit = limit
    end

    def call
      people = candidate_people
      return [] if people.empty?

      ids = people.map(&:id)
      scores = score_map(ids)
      answered = answer_counts(ids)
      live_ids = live_person_ids(ids)
      states = states_by_person_id(ids)

      people
        .sort_by { |rival| [ live_ids.include?(rival.id) ? 0 : 1, -(scores[rival.id] || 0), rival.given_name_key, rival.family_name_key, rival.id ] }
        .first(@limit)
        .each_with_index.map do |rival, index|
          Row.new(
            rank: index + 1,
            person: rival,
            score: scores[rival.id].to_i,
            answered: answered[rival.id].to_i,
            live: live_ids.include?(rival.id),
            state: states[rival.id]
          )
        end
    end

    private

      def candidate_people
        scope = @ward.people.where.not(id: @person.id)
        if @q.present?
          key = Person.name_key(@q)
          return [] if key.blank?

          return scope.where("given_name_key LIKE :key OR family_name_key LIKE :key", key: "#{key}%")
            .order(:given_name_key, :family_name_key, :id)
            .to_a
        end

        live_ids = live_person_ids(scope.pluck(:id))
        ranked_ids = Quizzes::Leaderboard.call(ward: @ward, person: @person, limit: 50).rows
          .map { |row| row.person.id }
          .reject { |id| id == @person.id }
        extra_ids = scope.order(:given_name_key, :family_name_key, :id).limit(@limit).pluck(:id)
        ids = (live_ids.to_a + ranked_ids + extra_ids).uniq
        return [] if ids.empty?

        scope.where(id: ids).to_a
      end

      def score_map(person_ids)
        Quizzes::Leaderboard.call(ward: @ward, person: @person, limit: 50).rows
          .select { |row| person_ids.include?(row.person.id) }
          .to_h { |row| [ row.person.id, row.score ] }
      end

      def answer_counts(person_ids)
        return {} if person_ids.empty?

        QuizAnswer.joins(:quiz_run)
          .where(quiz_runs: { person_id: person_ids })
          .group("quiz_runs.person_id")
          .count
      end

      def live_person_ids(person_ids)
        return Set.new if person_ids.blank?

        street = PersonDevice.where(person_id: person_ids).live.distinct.pluck(:person_id)
        night = Player.where(person_id: person_ids).live.distinct.pluck(:person_id)
        Set.new(street + night)
      end

      def states_by_person_id(person_ids)
        return {} if @pack_id.blank? || person_ids.empty?

        duels = StreetDuel
          .where(pack_id: @pack_id)
          .where("challenger_person_id = :id OR opponent_person_id = :id", id: @person.id)
          .where(status: %w[pending challenger_done opponent_done resolved])
          .where("challenger_person_id IN (:ids) OR opponent_person_id IN (:ids)", ids: person_ids)
          .order(updated_at: :desc, id: :desc)

        states = {}
        duels.each do |duel|
          other_id = duel.challenger_person_id == @person.id ? duel.opponent_person_id : duel.challenger_person_id
          next if other_id.blank? || states.key?(other_id)

          states[other_id] = state_for(duel)
        end
        states
      end

      def state_for(duel)
        if duel.resolved?
          return :tie if duel.challenger_score == duel.opponent_score
          return :won if duel.winner_person&.id == @person.id

          :lost
        elsif duel.opponent_person_id == @person.id
          :incoming
        else
          :waiting
        end
      end
  end
end
