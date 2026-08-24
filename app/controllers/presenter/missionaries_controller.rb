module Presenter
  class MissionariesController < ApplicationController
    before_action :set_night, :require_presenter

    def create
      Missionaries::Add.call(night: @night, name: params[:name])
      redirect_to presenter_roster_path(@night.code)
    rescue People::Error => error
      redirect_to presenter_roster_path(@night.code), alert: error.message
    end

    def destroy
      missionary = @night.missionaries.find(params[:id])
      Missionaries::Remove.call(night: @night, missionary:)
      redirect_to presenter_roster_path(@night.code)
    end
  end
end
