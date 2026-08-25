class GameSessionsController < ApplicationController
  before_action :require_ward_presenter, only: :create

  def new
    ward = hosted_ward || current_ward
    if ward
      redirect_to ward_profile_path(ward.code)
    else
      redirect_to root_path
    end
  end

  def create
    @night = Nights::Start.call(ward: hosted_ward)
    Presenters::Seat.call(night: @night, device_token: device_token)
    remember_presenter(@night)
    remember_ward_host(hosted_ward)
    Rails.logger.info("session=#{@night.code} event=created ward=#{hosted_ward.code}")
    redirect_to created_game_session_path(@night, token: @night.presenter_token)
  end

  def created
    @night = GameSession.find(params[:id])
    unless presenter_for?(@night) && @night.presenter_token_matches?(params[:token].to_s)
      redirect_to root_path, alert: I18n.t("flashes.bad_link")
      return
    end
  end
end
