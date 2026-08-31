module Quizzes
  class Complete
    Summary = Struct.new(
      :score, :average, :n, :first, :standings, :pack_board, :total_board,
      :rank_up, :duel_impacts,
      :answered, :correct, :max_streak, :duration_s, :last_gain,
      :base_score, :streak_bonus,
      keyword_init: true
    )

    def self.call(run:)
      raise "Not done" unless run.open? && run.last_question? && run.settled?

      ApplicationRecord.transaction do
        locked = QuizRun.lock.find(run.id)
        raise "Not done" unless locked.open? && locked.last_question? && locked.settled?

        reward = StreakReward.summary(run: locked)
        locked.update!(
          status: "finished",
          ends_at: nil,
          base_score: reward.base_points,
          fire_count: reward.max_streak,
          fire_bonus: reward.streak_bonus
        )
      end
      run.reload
      if run.live?
        Nights::Events.emit(
          night: run.game_session,
          kind: "quiz_finish",
          dedupe_key: "quiz-finish:#{run.id}",
          payload: { player_id: run.player_id, player_name: run.player.name, team_id: run.team_id, team_name: run.team.name, score: run.score, pack_id: run.pack_id }
        )
      else
        DuelRunFanout.call(run:)
      end
      run
    end

    def self.summary(run, ward: nil, person: nil)
      finished = QuizRun.street.where(pack_id: run.pack_id, status: "finished")
      n = finished.count
      average = n >= 2 ? finished.average(:score).to_f.round : nil
      ward ||= person&.ward
      standings = !run.live? && ward && person ? Standings.call(ward:, person:, pack_id: run.pack_id) : nil
      pack_board = standings&.pack_board
      pack_board ||= !run.live? && ward ? Leaderboard.call(ward:, pack_id: run.pack_id, person:, limit: 3) : nil
      total_board = standings&.total_board
      total_board ||= !run.live? && ward ? Leaderboard.call(ward:, person:, limit: 3) : nil
      answers = run.quiz_answers.to_a
      last_q = run.pack.question_at(run.position)
      last_answer = answers.find { |row| row.question_id == last_q.id }
      reward = StreakReward.summary(run:)
      Summary.new(
        score: run.score.to_i,
        average:,
        n:,
        first: n < 2,
        standings:,
        pack_board:,
        total_board:,
        rank_up: !run.live? && rank_up?(person, run),
        duel_impacts: run.live? ? [] : DuelCampus.call(person:, run:).impacts,
        answered: answers.size,
        correct: answers.count(&:correct?),
        max_streak: HitStreak.max_count(run:),
        duration_s: answer_duration_s(run, answers),
        last_gain: last_answer&.points_awarded.to_i.presence || (last_answer&.correct? ? last_q.points.to_i : 0),
        base_score: reward.base_points,
        streak_bonus: reward.streak_bonus
      )
    end

    def self.duels_for(run)
      return StreetDuel.none unless run

      StreetDuel.where("challenger_run_id = :id OR opponent_run_id = :id", id: run.id).order(:id)
    end

    def self.rank_up?(person, run)
      return false unless person

      after_total = QuizDefinition.catalog.pack_ids.sum { |pid| best_for_pack(person, pid) }
      previous_best = QuizRun.street.finished
        .where(person_id: person.id, pack_id: run.pack_id)
        .where.not(id: run.id)
        .maximum(:score)
        .to_i
      before_total = after_total - run.score + previous_best
      rank_index(rank_key_for(after_total)) > rank_index(rank_key_for(before_total))
    end

    def self.total_best(person, excluding_pack: nil)
      QuizDefinition.catalog.pack_ids.sum do |pack_id|
        next 0 if pack_id == excluding_pack

        best_for_pack(person, pack_id)
      end
    end

    def self.best_for_pack(person, pack_id)
      QuizRun.street.finished.where(person_id: person.id, pack_id:).maximum(:score).to_i
    end

    def self.rank_key_for(score)
      Team::RANKS.reverse.find { |threshold, _, _| score >= threshold }&.second || Team::RANKS.first.second
    end

    def self.rank_index(key)
      Team::RANKS.index { |_, rank_key, _| rank_key == key } || 0
    end

    def self.unlock_pack_id(run)
      return nil unless first_finish?(run)

      ids = QuizDefinition.catalog.pack_ids
      idx = ids.index(run.pack_id)
      return nil unless idx && idx < ids.size - 1

      ids[idx + 1]
    end

    def self.first_finish?(run)
      QuizRun.street.finished
        .where(pack_id: run.pack_id, device_digest: run.device_digest, person_id: run.person_id)
        .where.not(id: run.id)
        .none?
    end

    def self.answer_duration_s(run, answers)
      if answers.any? { |row| !row.duration_ms.nil? }
        (answers.sum { |row| row.duration_ms.to_i } / 1000.0).round
      else
        last_at = answers.map(&:created_at).max || run.updated_at
        [ (last_at - run.opened_at).to_i, 0 ].max
      end
    end
    private_class_method :answer_duration_s

  end
end
