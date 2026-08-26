class WardProfilesController < ApplicationController
  def show
    @ward = Wards::Enter.call(code: params[:code])
    remember_ward(@ward)
    @live_night = @ward.live_night
    @nights = @ward.game_sessions.includes(:missionaries).order(updated_at: :desc)
  rescue People::Error
    redirect_to root_path, alert: I18n.t("errors.people.ward_missing")
  end
end
