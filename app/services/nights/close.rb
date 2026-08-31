module Nights
  class Close
    def self.call(night:, at: Time.current)
      new(night:, at:).call
    end

    def initialize(night:, at:)
      @night = night
      @at = at
    end

    def call
      GameSession.transaction do
        @night.lock!
        return @night if @night.closed_at?

        @night.quiz_runs.open_runs.update_all(status: "expired", expired_at: @at, ends_at: nil, updated_at: @at)
        scores = @night.quiz_runs.group(:team_id).sum(:score)
        @night.teams.find_each { |team| team.update_columns(cached_score: scores[team.id].to_i, updated_at: @at) }
        @night.update_columns(status: "finished", closed_at: @at, updated_at: @at)
        Nights::Events.emit(
          night: @night,
          kind: "night_close",
          dedupe_key: "night-close:#{@night.ends_at.to_i}",
          payload: { closed_at: @at.iso8601 }
        )
      end
      @night.reload
    end
  end
end
