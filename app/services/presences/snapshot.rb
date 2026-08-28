module Presences
  class Snapshot
    Result = Struct.new(:joined, :live, :room, :remote, :teams, :live_player_ids, keyword_init: true)
    TeamCount = Struct.new(:team, :joined, :live, keyword_init: true)

    def self.call(night:)
      new(night).call
    end

    def initialize(night)
      @night = night
    end

    def call
      people = @night.players.where(role: "participant").includes(:team).to_a
      live_player_ids = Registry.online_player_ids(night_id: @night.id)
      live = people.select { |player| live_player_ids.include?(player.id) }
      teams = @night.teams.includes(:players).order(:name).map do |team|
        members = team.players.select(&:participant?)
        TeamCount.new(team: team, joined: members.size, live: members.count { |member| live_player_ids.include?(member.id) })
      end

      Result.new(
        joined: people.size,
        live: live.size,
        room: live.count { |player| !player.remote? },
        remote: live.count(&:remote?),
        teams:,
        live_player_ids:
      )
    end
  end
end
