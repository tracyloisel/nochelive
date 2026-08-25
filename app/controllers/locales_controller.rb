class LocalesController < ApplicationController
  def update
    locale = Locale.cast(params[:locale])
    remember_locale(locale)

    if params[:session_code].present?
      set_night
      if current_player
        Locales::Set.call(locale:, player: current_player)
      elsif presenter_for?(@night)
        Locales::Set.call(locale:, night: @night, presenter: true)
      end
    end

    redirect_back fallback_location: root_path
  end
end
