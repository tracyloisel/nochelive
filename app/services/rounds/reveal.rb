module Rounds
  class Reveal
    def self.call(round:)
      new(round:).call
    end

    def initialize(round:)
      @round = round
    end

    def call
      Answers::GradeChoices.call(round: @round)
      @round.reveal! unless @round.revealed? || @round.completed?
      @round.game_session.broadcast_state(pulse: { kind: "reveal" })
      @round
    end
  end
end
