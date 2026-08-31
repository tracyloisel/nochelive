class JoinsController < ApplicationController
  def create
    code = GameSession.normalize_code(params[:code])
    night = GameSession.find_by_code(code)

    if night.nil?
      redirect_to root_path, alert: I18n.t("flashes.night_missing")
      return
    end

    remember_ward(night.ward)

    redirect_to night_path(night.code)
  end
end
