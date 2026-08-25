module Rounds
  class Lock
    def self.call(round:)
      new(round:).call
    end

    def initialize(round:)
      @round = round
    end

    def call
      @round.lock! if @round.open?
      Votes::Tally.call(round: @round.reload) if @round.definition.vote?
      pulse = if @round.definition.layered_finale? && @round.finale_steal_open?
        { kind: "open" }
      else
        { kind: "lock" }
      end
      @round.game_session.broadcast_state(pulse: pulse)
      @round
    end
  end
end
