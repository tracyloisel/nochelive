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
      raise People::Error.new(:team, "Ese equipo no es de esta noche.") unless @team.game_session_id == @night.id
      return @player.team_membership if @player.team_membership&.team_id == @team.id

      ApplicationRecord.transaction do
        @player.team_membership&.destroy
        membership = TeamMembership.create!(player: @player, team: @team)
        if @player.person && @team.ward_team
          @player.person.update!(last_ward_team: @team.ward_team)
        end
        @night.broadcast_state
        membership
      end
    end
  end
end
