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
      @round.game_session.broadcast_state(pulse: { kind: "lock" })
      @round
    end
  end
end
