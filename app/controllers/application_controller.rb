class ApplicationController < ActionController::Base
  include Identity
  allow_browser versions: :modern unless Rails.env.test?
  before_action :load_night_for_locale
  around_action :use_locale

  private

    def load_night_for_locale
      code = params[:session_code]
      return if code.blank? || @night

      @night = GameSession.find_by(code: GameSession.normalize_code(code))
    end

    def use_locale(&block)
      I18n.with_locale(current_locale, &block)
    end
end
