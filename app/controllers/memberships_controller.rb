class MembershipsController < ApplicationController
  before_action :set_night, :require_player, :require_participant_profile

  def create
    team = @night.teams.find(params[:team_id])
    Memberships::Join.call(night: @night, player: current_player, team:)
    redirect_to night_play_path(@night.code)
  rescue People::Error => error
    redirect_to night_play_path(@night.code), alert: error.message
  end
end
