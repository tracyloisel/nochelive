module Presences
  class Snapshot
    Result = Struct.new(:joined, :live, :room, :remote, :teams, keyword_init: true)
    TeamCount = Struct.new(:team, :joined, :live, keyword_init: true)
    LIVE_WINDOW = 25.seconds

    def self.call(night:)
      new(night).call
    end

    def initialize(night)
      @night = night
    end

    def call
      people = @night.players.where(role: "participant").includes(:team).to_a
      live = people.select(&:live?)
      teams = @night.teams.includes(:players).order(:name).map do |team|
        members = team.players.select(&:participant?)
        TeamCount.new(team: team, joined: members.size, live: members.count(&:live?))
      end

      Result.new(
        joined: people.size,
        live: live.size,
        room: live.count { |player| !player.remote? },
        remote: live.count(&:remote?),
        teams: teams
      )
    end
  end
end
