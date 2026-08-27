class PlayController < ApplicationController
  before_action :set_night, :require_player

  def show
    if current_player.spectator?
      redirect_to night_watch_path(@night.code)
      return
    end

    if current_player&.participant? && current_player.remote? && current_team.nil?
      Teams::Seat.call(night: @night, player: current_player)
      current_player.reload
    end
    @player = current_player
    @team = current_team
    @round = @night.current_round_run
  end
end
