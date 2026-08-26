module Quizzes
  class ChallengeResolve
    Result = Struct.new(:duel, :winner, :tie, keyword_init: true)

    def self.call(duel:)
      new(duel:).call
    end

    def self.after_run!(run:)
      duel = StreetDuel.find_by(challenger_run_id: run.id) ||
        StreetDuel.find_by(opponent_run_id: run.id)
      return unless duel

      if duel.challenger_run_id == run.id
        duel.update!(challenger_score: run.score)
        duel.update!(status: "challenger_done") unless duel.opponent_score || duel.opponent_run&.finished?
      elsif duel.opponent_run_id == run.id
        duel.update!(opponent_score: run.score)
        duel.update!(status: "opponent_done") unless duel.challenger_score || duel.challenger_run&.finished?
      end

      call(duel: duel.reload)
    end

    def initialize(duel:)
      @duel = duel
    end

    def call
      return Result.new(duel: @duel, winner: @duel.winner_person, tie: tie?) if @duel.resolved?

      challenger_score = @duel.challenger_score || @duel.challenger_run&.score
      opponent_score = @duel.opponent_score || @duel.opponent_run&.score
      return Result.new(duel: @duel, winner: nil, tie: false) unless challenger_score && opponent_score

      @duel.update!(
        status: "resolved",
        challenger_score:,
        opponent_score:
      )
      Result.new(duel: @duel.reload, winner: @duel.winner_person, tie: tie?)
    end

    private

      def tie?
        @duel.challenger_score == @duel.opponent_score
      end
  end
end
