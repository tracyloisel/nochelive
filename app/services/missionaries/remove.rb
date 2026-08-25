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
      raise People::Error.new(:missing, I18n.t("errors.people.missionary_missing")) unless @missionary.game_session_id == @night.id

      @missionary.destroy!
      @night.broadcast_state
      @missionary
    end
  end
end
