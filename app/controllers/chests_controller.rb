class ChestsController < ApplicationController
  before_action :set_night, :require_player, :require_team

  def create
    grant = current_team.reward_grants.find(params[:id])
    grant.open! if grant.ready?
    @night.broadcast_state
    redirect_to night_play_path(@night.code)
  rescue RuntimeError
    redirect_to night_play_path(@night.code)
  end
end
