module Missionaries
  class Remove
    def self.call(night:, missionary:)
      new(night:, missionary:).call
    end

    def initialize(night:, missionary:)
      @night = night
      @missionary = missionary
    end

    def call
      raise People::Error.new(:missing, "Ese nombre no está en esta noche.") unless @missionary.game_session_id == @night.id

      @missionary.destroy!
      @night.broadcast_state
      @missionary
    end
  end
end
