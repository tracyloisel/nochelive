class GameSessionsController < ApplicationController
  def new
    @ward = current_ward
  end

  def create
    unless current_ward
      redirect_to new_ward_path, alert: "Primero abre tu rama."
      return
    end

    @night = Nights::Start.call(ward: current_ward)
    remember_presenter(@night)
    remember_ward(current_ward)
    Rails.logger.info("session=#{@night.code} event=created ward=#{current_ward.code}")
    redirect_to created_game_session_path(@night, token: @night.presenter_token)
  end

  def created
    @night = GameSession.find(params[:id])
    unless presenter_for?(@night) && @night.presenter_token_matches?(params[:token].to_s)
      redirect_to root_path, alert: "Ese enlace ya no es válido."
      return
    end
  end
end
