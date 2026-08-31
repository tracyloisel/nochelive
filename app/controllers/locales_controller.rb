class LocalesController < ApplicationController
  def update
    locale = Locale.cast(params[:locale])
    remember_locale(locale)

    if params[:session_code].present?
      set_night
      Locales::Set.call(locale:, player: current_player) if current_player
    end

    redirect_back fallback_location: root_path
  end
end
