class TeamsController < ApplicationController
  before_action :set_night, :require_player

  def create
    team = Teams::Create.call(
      night: @night,
      name: params.require(:name),
      emblem: params[:emblem],
      player: current_player
    )
    redirect_to night_play_path(@night.code)
  rescue People::Error => error
    redirect_to night_play_path(@night.code), alert: error.message
  end
end
