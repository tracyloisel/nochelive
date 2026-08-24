class JoinsController < ApplicationController
  def create
    code = GameSession.normalize_code(params[:code])
    night = GameSession.find_by(code: code)
    night = GameSession.where("upper(code) = ?", code).where.not(status: "finished").first if night.nil?

    if night.nil?
      redirect_to root_path, alert: "Esa noche no existe."
      return
    end

    if params[:as] == "watch"
      redirect_to night_watch_path(night.code)
    else
      redirect_to night_name_path(night.code)
    end
  end
end
