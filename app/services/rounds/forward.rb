module Rounds
  class Forward
    def self.call(round:, team:)
      new(round:, team:).call
    end

    def initialize(round:, team:)
      @round = round
      @team = team
      @night = round.game_session
    end

    def call
      raise "Not a quiz round" unless @round.definition.choice?
      raise "Answer first" unless @team.answers.exists?(round_run: @round)

      next_round = nil
      ApplicationRecord.transaction do
        @round.reveal! unless @round.revealed? || @round.completed?
        @round.complete! unless @round.completed?
        next_round = @night.round_runs.find_by(position: @round.position + 1)
        if next_round
          next_round.intro! if next_round.pending?
          next_round.open! unless next_round.open? || next_round.completed?
        end
      end

      if next_round
        @night.broadcast_state(pulse: { kind: "open" })
      else
        Nights::Finish.call(night: @night)
      end

      next_round
    end
  end
end
