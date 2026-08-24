module Buzzes
  class Accept
    def self.call(round_run:, team:, player:)
      new(round_run:, team:, player:).call
    end

    def initialize(round_run:, team:, player:)
      @round_run = round_run
      @team = team
      @player = player
    end

    def call
      raise "Round is not open" unless @round_run.accepting_buzzes?

      ApplicationRecord.transaction do
        locked = RoundRun.lock.find(@round_run.id)
        raise "Round is not open" unless locked.accepting_buzzes?

        existing = Buzz.find_by(round_run: locked, team: @team)
        return existing if existing

        position = Buzz.where(round_run: locked).maximum(:position).to_i + 1
        Buzz.create!(
          round_run: locked,
          team: @team,
          player: @player,
          position: position,
          latency_ms: latency_ms_for(locked)
        )
      end
    end

    private

    def latency_ms_for(round)
      opened = round.opened_at
      return 0 if opened.blank?

      [ ((Time.current - opened) * 1000).round, 0 ].max
    end
  end
end
