module Presenter
  class PeopleController < ApplicationController
    before_action :set_night, :require_presenter

    def create
      player = @night.players.find(params[:player_id])
      person = @night.ward.people.find(params[:person_id].presence || params[:id])
      People::LinkDevice.call(night: @night, player:, person:)
      @night.broadcast_state
      redirect_to presenter_console_path(@night.code)
    rescue People::Error => error
      redirect_to presenter_console_path(@night.code), alert: error.message
    end
  end
end
