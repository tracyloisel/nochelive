module Presenter
  class RostersController < ApplicationController
    before_action :set_night, :require_presenter

    def show
      @teams = @night.teams.includes(players: :person).order(:name)
      @unassigned = @night.players.participants.includes(:person).left_joins(:team_membership).where(team_memberships: { id: nil })
      @missionaries = @night.missionaries
    end
  end
end
