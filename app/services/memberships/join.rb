module Memberships
  class Join
    def self.call(night:, player:, team:)
      new(night:, player:, team:).call
    end

    def initialize(night:, player:, team:)
      @night = night
      @player = player
      @team = team
    end

    def call
      raise People::Error.new(:team, I18n.t("errors.people.team_night")) unless @team.game_session_id == @night.id
      return @player.team_membership if @player.team_membership&.team_id == @team.id
      if @player.quiz_runs.live.exists?
        raise People::Error.new(:team, I18n.t("nights.team_locked"))
      end

      ApplicationRecord.transaction do
        @player.team_membership&.destroy
        membership = TeamMembership.create!(player: @player, team: @team)
        if @player.person && @team.ward_team
          @player.person.update!(last_ward_team: @team.ward_team)
        end
        Nights::Events.emit(
          night: @night,
          kind: "team_join",
          dedupe_key: "team-join:#{@player.id}:#{@team.id}",
          payload: { player_id: @player.id, player_name: @player.name, team_id: @team.id, team_name: @team.name }
        )
        membership
      end
    end
  end
end
