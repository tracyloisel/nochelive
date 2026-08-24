module Presenter
  class NightsController < ApplicationController
    before_action :set_night, :require_presenter

    def start
      @night.start_playing!
      Rails.logger.info("session=#{@night.code} event=start")
      @night.broadcast_state
      redirect_to presenter_console_path(@night.code)
    end

    def pause
      @night.pause!
      @night.broadcast_state
      redirect_to presenter_console_path(@night.code)
    end

    def resume
      @night.resume!
      @night.broadcast_state
      redirect_to presenter_console_path(@night.code)
    end

    def finish
      Nights::Finish.call(night: @night)
      Rails.logger.info("session=#{@night.code} event=finish")
      redirect_to presenter_console_path(@night.code)
    end

    def crown
      round = @night.round_runs.find(params[:id])
      Nights::Crown.call(night: @night, round:)
      Rails.logger.info("session=#{@night.code} round=#{round.yaml_round_id} event=crown")
      redirect_to presenter_console_path(@night.code)
    rescue RuntimeError
      redirect_to presenter_console_path(@night.code)
    end
  end
end
