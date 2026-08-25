class WardMemoriesController < ApplicationController
  def show
    @ward = Wards::Enter.call(code: params[:code])
    code = GameSession.normalize_code(params[:session_code])
    nights = @ward.game_sessions.where(code: code)
    @night = nights.live.order(updated_at: :desc).first || nights.order(updated_at: :desc).first!
    remember_ward(@ward)
    redirect_to night_name_path(@night.code) if @night.live?
  rescue People::Error
    redirect_to root_path, alert: I18n.t("errors.people.ward_missing")
  end
end
