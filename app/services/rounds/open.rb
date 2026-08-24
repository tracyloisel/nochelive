module Rounds
  class Open
    def self.call(round:)
      new(round:).call
    end

    def initialize(round:)
      @round = round
    end

    def call
      @round.intro! if @round.pending?
      @round.open! unless @round.open? || @round.completed?
      @round.game_session.broadcast_state
      @round
    end
  end
end
