module Missionaries
  class Add
    def self.call(night:, name:)
      new(night:, name:).call
    end

    def initialize(night:, name:)
      @night = night
      @name = name.to_s.strip.first(32)
    end

    def call
      raise People::Error.new(:name, I18n.t("errors.people.missionary")) if @name.blank?

      missionary = @night.missionaries.create!(name: @name)
      @night.broadcast_state
      missionary
    end
  end
end
