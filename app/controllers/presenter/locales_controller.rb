module Presenter
  class LocalesController < ApplicationController
    before_action :set_night, :require_presenter

    def update
      locale = Locale.cast(params[:locale])
      player = @night.players.find_by(id: params[:player_id])
      person = @night.ward&.people&.find_by(id: params[:person_id])
      Locales::Assign.call(night: @night, locale:, player:, person:)
      redirect_back fallback_location: presenter_roster_path(@night.code)
    rescue People::Error => error
      redirect_back fallback_location: presenter_roster_path(@night.code), alert: error.message
    end
  end
end
