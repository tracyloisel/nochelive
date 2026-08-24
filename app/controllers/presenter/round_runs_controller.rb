module Presenter
  class RoundRunsController < ApplicationController
    before_action :set_night, :require_presenter
    before_action :set_round

    def open
      @round.intro! if @round.pending?
      @round.open!
      Rails.logger.info("session=#{@night.code} round=#{@round.yaml_round_id} event=open")
      @night.broadcast_state
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
      @round.complete! unless @round.completed?
      next_round = @night.round_runs.find_by(position: @round.position + 1)
      if next_round
        next_round.intro!
      else
        @night.finish!
      end
      Rails.logger.info("session=#{@night.code} round=#{@round.yaml_round_id} event=complete")
      @night.broadcast_state
      redirect_to presenter_console_path(@night.code)
    end

    private

    def set_round
      @round = @night.round_runs.find(params[:id])
    end
  end
end
