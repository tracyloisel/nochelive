module Quizzes
  class Complete
    Summary = Struct.new(
      :score, :average, :n, :first, :standings, :pack_board, :total_board,
      :stars_earned, :rank_up, :duel_token,
      :answered, :correct, :max_streak, :duration_s, :last_gain, :shout_key,
      :base_score, :fire_count, :fire_percent, :fire_bonus,
      keyword_init: true
    )

    def self.call(run:)
      raise "Not done" unless run.open? && run.last_question? && run.settled?

      ApplicationRecord.transaction do
        locked = QuizRun.lock.find(run.id)
        raise "Not done" unless locked.open? && locked.last_question? && locked.settled?

        fire = FireBonus.call(run: locked)
        locked.update!(
          status: "finished",
          ends_at: nil,
          base_score: fire.base_score,
          fire_count: fire.fire_count,
          fire_bonus: fire.bonus,
          score: fire.total_score
        )
      end
      ChallengeResolve.after_run!(run: run.reload)
      run
    end

    def self.summary(run, ward: nil, person: nil)
      finished = QuizRun.where(pack_id: run.pack_id, status: "finished")
      n = finished.count
      average = n >= 2 ? finished.average(:score).to_f.round : nil
      ward ||= person&.ward
      standings = ward && person ? Standings.call(ward:, person:, pack_id: run.pack_id) : nil
      pack_board = standings&.pack_board
      pack_board ||= ward ? Leaderboard.call(ward:, pack_id: run.pack_id, person:, limit: 3) : nil
      total_board = standings&.total_board
      total_board ||= ward ? Leaderboard.call(ward:, person:, limit: 3) : nil
      stars_earned = Stars.call(score: run.score)
      answers = run.quiz_answers.to_a
      last_q = run.pack.question_at(run.position)
      last_answer = answers.find { |row| row.question_id == last_q.id }
      Summary.new(
        score: run.score.to_i,
        average:,
        n:,
        first: n < 2,
        standings:,
        pack_board:,
        total_board:,
        stars_earned:,
        rank_up: rank_up?(person, run),
        duel_token: pending_duel_token(person, run),
        answered: answers.size,
        correct: answers.count(&:correct?),
        max_streak: HitStreak.max_count(run:),
        duration_s: answer_duration_s(run, answers),
        last_gain: last_answer&.correct? ? last_q.points.to_i : 0,
        shout_key: shout_key_for(stars_earned),
        base_score: recorded_base_score(run),
        fire_count: run.fire_count.to_i,
        fire_percent: run.fire_count.to_i * FireBonus::PERCENT_PER_FIRE,
        fire_bonus: run.fire_bonus.to_i
      )
    end

    def self.duel_for(run)
      return unless run

      StreetDuel.where("challenger_run_id = :id OR opponent_run_id = :id", id: run.id).order(:id).last
    end

    def self.active_duel_for(run)
      return nil unless run.finished? && run.person_id

      duel_for(run)
    end

    def self.rank_up?(person, run)
      return false unless person

      after_total = QuizDefinition.catalog.pack_ids.sum { |pid| best_for_pack(person, pid) }
      previous_best = QuizRun.finished
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
      QuizRun.finished.where(person_id: person.id, pack_id:).maximum(:score).to_i
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
      QuizRun.finished
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

    def self.recorded_base_score(run)
      return run.base_score.to_i if run.base_score.to_i.positive? || run.fire_bonus.to_i.positive?

      run.score.to_i
    end
    private_class_method :recorded_base_score

    def self.shout_key_for(stars)
      return "legend" if stars.to_i >= 3
      return "great" if stars.to_i >= 2

      "done"
    end

    def self.pending_duel_token(person, run)
      return nil unless person

      duel = StreetDuel.active.not_expired
        .where(challenger_person_id: person.id, pack_id: run.pack_id)
        .where(status: %w[pending challenger_done])
        .order(:id)
        .last
      duel&.token
    end
  end
end
