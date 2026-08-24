module Presenter
  class GatesController < ApplicationController
    before_action :set_night

    def show
      if params[:token].present? && @night.presenter_token_matches?(params[:token])
        remember_presenter(@night)
        remember_ward(@night.ward)
        redirect_to presenter_console_path(@night.code)
        return
      end

      redirect_to presenter_console_path(@night.code) if presenter_for?(@night)
    end

    def create
      if @night.presenter_token_matches?(params[:token].to_s)
        remember_presenter(@night)
        remember_ward(@night.ward)
        redirect_to presenter_console_path(@night.code)
      else
        redirect_to presenter_gate_path(@night.code), alert: "Token incorrecto."
      end
    end
  end
end
