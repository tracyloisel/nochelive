class PlayController < ApplicationController
  before_action :set_night, :require_player

  def show
    @player = current_player
    @team = current_team
    @round = @night.current_round_run
  end
end
