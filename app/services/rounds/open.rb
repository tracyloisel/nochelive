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
      if @round.definition.layered_finale? && @round.layer_index.to_i.zero? && !@round.open?
        return Rounds::Peel.call(round: @round)
      end
      if @round.burger_assembled?
        return open_now!
      end

      open_now!
    end

    private

      def open_now!
        opened = false
        unless @round.open? || @round.completed?
          @round.open!
          opened = true
        end
        @round.game_session.broadcast_state(pulse: ({ kind: "open" } if opened))
        @round
      end
  end
end
