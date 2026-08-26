module Quizzes
  class Complete
    Summary = Struct.new(
      :score, :average, :n, :first, :standings, :pack_board, :total_board,
      :stars_earned, :rank_up, :duel_token,
      keyword_init: true
    )

    def self.call(run:)
      raise "Not done" unless run.open? && run.last_question? && run.settled?

      run.update!(status: "finished", ends_at: nil)
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
      pack_board ||= ward ? Leaderboard.call(ward:, pack_id: run.pack_id, person:, limit: 4) : nil
      stars_earned = Stars.call(score: run.score)
      Summary.new(
        score: run.score.to_i,
        average:,
        n:,
        first: n < 2,
        standings:,
        pack_board:,
        total_board: standings&.total_board,
        stars_earned:,
        rank_up: rank_up?(person, run),
        duel_token: pending_duel_token(person, run)
      )
    end

    def self.active_duel_for(run)
      return nil unless run.finished? && run.person_id

      StreetDuel.not_expired
        .where(pack_id: run.pack_id)
        .where("challenger_run_id = ? OR opponent_run_id = ?", run.id, run.id)
        .order(:id)
        .last
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
