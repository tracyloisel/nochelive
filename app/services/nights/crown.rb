module Nights
  class Crown
    def self.call(night:, round:)
      new(night:, round:).call
    end

    def initialize(night:, round:)
      @night = night
      @round = round
    end

    def call
      raise "Not the finale" unless @round.definition.finale?

      @round.reveal! if @round.phase.in?(%w[open locked answering])
      @round.complete! if @round.may_complete?
      @night.update!(status: "finished")
      @night.broadcast_state
      @night
    end
  end
end
