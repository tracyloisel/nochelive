module Rounds
  class Peel
    def self.call(round:)
      new(round:).call
    end

    def initialize(round:)
      @round = round
    end

    def call
      raise "Not a burger" unless @round.definition.layered_finale?

      @round.intro! if @round.pending?
      return @round if @round.open? || @round.completed? || @round.last_layer?

      @round.update!(layer_index: @round.layer_index + 1)
      pulse = @round.last_layer? ? nil : { kind: "advance" }
      @round.game_session.broadcast_state(pulse: pulse)
      @round
    end
  end
end
