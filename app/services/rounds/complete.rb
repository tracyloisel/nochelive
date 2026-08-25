module Rounds
  class Complete
    def self.call(round:)
      new(round:).call
    end

    def initialize(round:)
      @round = round
      @night = round.game_session
    end

    def call
      @round.complete! unless @round.completed?
      next_round = @night.round_runs.find_by(position: @round.position + 1)
      if next_round
        changed = next_round.pending?
        next_round.intro! if next_round.pending?
        @night.broadcast_state(pulse: ({ kind: "advance" } if changed))
      else
        Nights::Finish.call(night: @night)
      end
      @round
    end
  end
end
