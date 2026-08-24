class FreezesController < ApplicationController
  before_action :set_night, :require_player, :require_team

  def create
    round = @night.round_runs.find(params[:round_run_id])
    Freezes::Catch.call(round:, team: current_team, player: current_player)
    Rails.logger.info("session=#{@night.code} round=#{round.yaml_round_id} team=#{current_team.id} event=freeze")
    redirect_to night_play_path(@night.code)
  rescue RuntimeError, ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    redirect_to night_play_path(@night.code)
  end
end
