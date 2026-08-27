module Quizzes
  class ChallengeResolve
    Result = Struct.new(:duel, :winner, :tie, keyword_init: true)

    def self.call(duel:)
      new(duel:).call
    end

    def self.after_run!(run:)
      new(duel: nil).apply_run!(run)
    end

    def initialize(duel:)
      @duel = duel
    end

    def call
      apply_run!(nil)
    end

    def apply_run!(run)
      return unless run.nil? || run.finished?

      ApplicationRecord.transaction do
        duel = lock_duel_for(run)
        return Result.new(duel: nil, winner: nil, tie: false) unless duel
        if duel.resolved?
          if duel.challenger_delta.nil? || duel.opponent_delta.nil?
            duel.update!(delta_attrs(duel.challenger_score.to_i, duel.opponent_score.to_i))
          end
          return result_for(duel.reload)
        end

        attrs = score_attrs(duel, run)
        return result_for(duel) if attrs.empty? && run

        challenger_score = attrs[:challenger_score] || finished_score(duel.challenger_score, duel.challenger_run)
        opponent_score = attrs[:opponent_score] || finished_score(duel.opponent_score, duel.opponent_run)

        if !challenger_score.nil? && !opponent_score.nil?
          attrs[:status] = "resolved"
          attrs[:challenger_score] = challenger_score
          attrs[:opponent_score] = opponent_score
          attrs.merge!(delta_attrs(challenger_score, opponent_score))
        elsif attrs[:challenger_score] && duel.pending?
          attrs[:status] = "challenger_done"
        elsif attrs[:opponent_score] && (duel.pending? || duel.challenger_done?)
          attrs[:status] = "opponent_done" unless challenger_score
        end

        duel.update!(attrs) if attrs.any?
        run&.update!(street_duel: duel) if run&.street_duel_id != duel.id
        result_for(duel.reload)
      end
    end

    private

      def lock_duel_for(run)
        duel = @duel || find_duel_for(run)
        return unless duel

        StreetDuel.lock.find(duel.id)
      end

      def find_duel_for(run)
        return unless run

        StreetDuel.find_by(challenger_run_id: run.id) ||
          StreetDuel.find_by(opponent_run_id: run.id) ||
          unmatched_challenger_duel(run)
      end

      def unmatched_challenger_duel(run)
        return unless run.person_id

        StreetDuel.active.not_expired.find_by(
          challenger_person_id: run.person_id,
          pack_id: run.pack_id,
          challenger_run_id: nil
        )
      end

      def score_attrs(duel, run)
        return {} unless run

        if duel.challenger_run_id == run.id || attach_challenger?(duel, run)
          {
            challenger_run_id: run.id,
            challenger_score: run.score
          }
        elsif duel.opponent_run_id == run.id || (duel.opponent_person_id == run.person_id && duel.pack_id == run.pack_id)
          {
            opponent_run_id: run.id,
            opponent_score: run.score
          }
        else
          {}
        end
      end

      def attach_challenger?(duel, run)
        duel.challenger_run_id.nil? &&
          duel.challenger_person_id == run.person_id &&
          duel.pack_id == run.pack_id
      end

      def finished_score(stored, run)
        return stored unless stored.nil?
        return unless run&.finished?

        run.score
      end

      def delta_attrs(challenger_score, opponent_score)
        if challenger_score == opponent_score
          { challenger_delta: 1, opponent_delta: 1 }
        elsif challenger_score > opponent_score
          { challenger_delta: 12, opponent_delta: -3 }
        else
          { challenger_delta: -3, opponent_delta: 12 }
        end
      end

      def result_for(duel)
        Result.new(duel:, winner: duel.winner_person, tie: tie?(duel))
      end

      def tie?(duel)
        duel.resolved? && duel.challenger_score == duel.opponent_score
      end
  end
end
