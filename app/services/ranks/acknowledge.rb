module Ranks
  class Acknowledge
    def self.call(team:)
      new(team:).call
    end

    def initialize(team:)
      @team = team
    end

    def call
      @team.update!(pending_rank_up: nil)
      @team.game_session.broadcast_state
      @team
    end
  end
end
