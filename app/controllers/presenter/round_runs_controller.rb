module Presenter
  class RoundRunsController < ApplicationController
    before_action :set_night, :require_presenter
    before_action :set_round

    def open
      Rounds::Open.call(round: @round)
      Rails.logger.info("session=#{@night.code} round=#{@round.yaml_round_id} event=open")
      redirect_to presenter_console_path(@night.code)
    end

    def peel
      Rounds::Peel.call(round: @round)
      Rails.logger.info("session=#{@night.code} round=#{@round.yaml_round_id} event=peel layer=#{@round.layer_index}")
      redirect_to presenter_console_path(@night.code)
    end

    def lock
      Rounds::Lock.call(round: @round)
      Rails.logger.info("session=#{@night.code} round=#{@round.yaml_round_id} event=lock")
      redirect_to presenter_console_path(@night.code)
    end

    def reveal
      Rounds::Reveal.call(round: @round)
      Rails.logger.info("session=#{@night.code} round=#{@round.yaml_round_id} event=reveal")
      redirect_to presenter_console_path(@night.code)
    end

    def complete
      Rounds::Complete.call(round: @round)
      Rails.logger.info("session=#{@night.code} round=#{@round.yaml_round_id} event=complete")
      redirect_to presenter_console_path(@night.code)
    end

    private

    def set_round
      @round = @night.round_runs.find(params[:id])
    end
  end
end
