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
      raise People::Error.new(:name, "Escribe el nombre del misionero.") if @name.blank?

      missionary = @night.missionaries.create!(name: @name)
      @night.broadcast_state
      missionary
    end
  end
end
