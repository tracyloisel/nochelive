class PlayController < ApplicationController
  before_action :set_night, :require_player

  def show
    @night.reconcile!
    return redirect_to(night_path(@night.code)) unless @night.open_for_team_selection?

    @player = current_player
    @team = current_team
    unless @team
      render :pick_team
      return
    end
    return redirect_to(night_path(@night.code)) unless @night.playable?

    @run = Nights::QuizSequence.current_or_start(
      night: @night,
      player: @player,
      device_digest: street_device_digest
    )
    @street = Quizzes::Draw.frame(@run, ward: @night.ward)
    @play_context = :live
  rescue RuntimeError => error
    redirect_to night_path(@night.code), alert: error.message
  end
end
