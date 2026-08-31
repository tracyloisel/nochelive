module Quizzes
  class DuelCampusFriends
    LIMIT = 8
    Row = Struct.new(:person, :score, :live, :state, :open_run, keyword_init: true)

    def self.call(person:, q: nil, limit: LIMIT)
      new(person:, q:, limit:).call
    end

    def initialize(person:, q:, limit:)
      @person = person
      @q = q.to_s.strip
      @limit = limit
    end

    def call
      return [] unless @person&.ward

      people = candidate_people.to_a
      ids = people.map(&:id)
      live_ids = Presences::Registry.online_person_ids(among: ids)
      scores = Leaderboard.total_scores(person_ids: ids)
      states = states_for(ids)
      open_runs = latest_open_runs(ids)
      people.sort_by do |person|
        [ live_ids.include?(person.id) && open_runs[person.id] ? 0 : 1, states[person.id] ? 0 : 1,
          -scores[person.id].to_i, person.given_name_key ]
      end.first(@limit).map do |person|
        Row.new(
          person:, score: scores[person.id].to_i, live: live_ids.include?(person.id),
          state: states[person.id], open_run: open_runs[person.id]
        )
      end
    end

    private

      def candidate_people
        scope = StakeScope.people_for(ward: @person.ward).where.not(id: @person.id)
        return scope.order(:given_name_key, :family_name_key, :id).limit(@limit * 3) if @q.blank?

        key = Person.name_key(@q)
        return Person.none if key.blank?

        scope.where("given_name_key LIKE :key OR family_name_key LIKE :key", key: "#{key}%")
          .order(:given_name_key, :family_name_key, :id)
          .limit(@limit * 3)
      end

      def states_for(ids)
        return {} if ids.empty?

        states = {}
        StreetDuel.active.not_expired
          .where("challenger_person_id = :me OR opponent_person_id = :me", me: @person.id)
          .where("challenger_person_id IN (:ids) OR opponent_person_id IN (:ids)", ids:)
          .order(updated_at: :desc, id: :desc)
          .each do |duel|
            other_id = duel.challenger_person_id == @person.id ? duel.opponent_person_id : duel.challenger_person_id
            states[other_id] = :active
          end
        DuelInvitation.open_state.not_expired.where(challenger_person: @person, recipient_person_id: ids).each do |invitation|
          states[invitation.recipient_person_id] ||= :invited
        end
        DuelInvitation.open_state.not_expired.where(challenger_person_id: ids, recipient_person: @person).each do |invitation|
          states[invitation.challenger_person_id] = :incoming unless states[invitation.challenger_person_id] == :active
        end
        states
      end

      def latest_open_runs(ids)
        QuizRun.street.open_runs.where(person_id: ids).order(id: :desc).each_with_object({}) do |run, rows|
          rows[run.person_id] ||= run
        end
      end
  end
end
