module Nights
  class Reconcile
    def self.call(night:, at: Time.current)
      new(night:, at:).call
    end

    def initialize(night:, at:)
      @night = night
      @at = at.in_time_zone
    end

    def call
      GameSession.transaction do
        @night.lock!
        target = @night.phase(at: @at).to_s
        return @night if @night.status == target

        return Nights::Close.call(night: @night, at: @at) if target == "finished"

        @night.update_columns(status: target, updated_at: @at)
        Nights::Events.emit(
          night: @night,
          kind: "night_open",
          dedupe_key: "phase:#{target}:#{@night.starts_at.to_i}",
          payload: { phase: target }
        ) if target.in?(%w[lobby playing])
      end
      @night.reload
    end
  end
end
