class RankUpsController < ApplicationController
  before_action :set_night, :require_player, :require_team

  def create
    Ranks::Acknowledge.call(team: current_team)
    redirect_to night_play_path(@night.code)
  end
end
