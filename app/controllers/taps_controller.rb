class TapsController < ApplicationController
  before_action :set_night, :require_player, :require_team

  def create
    round = @night.round_runs.find(params[:round_run_id])
    TapRun.tap!(round_run: round, team: current_team, player: current_player)
    @night.broadcast_state
    head :ok
  rescue RuntimeError, ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    head :unprocessable_entity
  end
end
