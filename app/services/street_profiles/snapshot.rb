module StreetProfiles
  class Snapshot
    Result = Struct.new(
      :person, :ward,
      :crowns, :rank, :ranked_people, :rank_key, :streak_days,
      :packs_completed, :study_runs_completed,
      :challenge_wins, :challenge_total, :active_challenges,
      :device_count, :highlight_count, :answer_count, :correct_answer_count,
      keyword_init: true
    )

    def self.call(person:)
      new(person:).call
    end

    def initialize(person:)
      @person = person
    end

    def call
      standings = Quizzes::Standings.call(ward: @person.ward, person: @person)
      crowns = standings&.total_score || Quizzes::Leaderboard.total_score(person: @person)
      duels = duel_scope
      answers = answer_scopes

      Result.new(
        person: @person,
        ward: @person.ward,
        crowns: crowns.to_i,
        rank: standings&.total_rank,
        ranked_people: standings&.total_players.to_i,
        rank_key: rank_key_for(crowns),
        streak_days: Quizzes::Streak.call(person_id: @person.id).days,
        packs_completed: QuizRun.street.finished.where(person_id: @person.id).distinct.count(:pack_id),
        study_runs_completed: @person.study_runs.completed.count,
        challenge_wins: wins_in(duels),
        challenge_total: duels.where(status: "resolved").count,
        active_challenges: duels.active.not_expired.count,
        device_count: @person.person_devices.count,
        highlight_count: @person.scripture_highlights.count,
        answer_count: answers.sum(&:count),
        correct_answer_count: answers.sum { |scope| scope.where(correct: true).count }
      )
    end

    private

      def duel_scope
        StreetDuel.where(
          "challenger_person_id = :person_id OR opponent_person_id = :person_id",
          person_id: @person.id
        )
      end

      def answer_scopes
        [
          QuizAnswer.joins(:quiz_run).where(quiz_runs: { person_id: @person.id }),
          StudyAnswer.joins(:study_run).where(study_runs: { person_id: @person.id })
        ]
      end

      def wins_in(duels)
        duels.where(status: "resolved").where(
          <<~SQL.squish,
            (challenger_person_id = :person_id AND challenger_score > opponent_score)
            OR (opponent_person_id = :person_id AND opponent_score > challenger_score)
          SQL
          person_id: @person.id
        ).count
      end

      def rank_key_for(score)
        Team::RANKS.reverse.find { |threshold, _key, _label| score.to_i >= threshold }&.second || Team::RANKS.first.second
      end
  end
end
