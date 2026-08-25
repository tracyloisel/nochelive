module Presenter
  class GatesController < ApplicationController
    before_action :set_night

    def show
      if params[:token].present? && @night.presenter_token_matches?(params[:token])
        admit_with_token
        return
      end

      redirect_to presenter_console_path(@night.code) if presenter_for?(@night)
    end

    def create
      if @night.presenter_token_matches?(params[:token].to_s)
        admit_with_token
      else
        redirect_to presenter_gate_path(@night.code), alert: I18n.t("flashes.bad_link")
      end
    end

    private

      def admit_with_token
        Presenters::Seat.call(night: @night, device_token: device_token, clear_pending: true)
        remember_presenter(@night)
        remember_ward(@night.ward)
        redirect_to presenter_console_path(@night.code)
      end
  end
end
