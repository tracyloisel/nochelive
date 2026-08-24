module Nights
  class Finish
    def self.call(night:)
      new(night:).call
    end

    def initialize(night:)
      @night = night
    end

    def call
      @night.finish!
      WardTeams::RecordNight.call(night: @night)
      @night.broadcast_state
      @night
    end
  end
end
