class PoseHoldsController < ApplicationController
  before_action :set_night, :require_player, :require_team

  def create
    round = @night.round_runs.find(params[:round_run_id])
    PoseHold.complete!(
      round_run: round,
      team: current_team,
      player: current_player,
      held_ms: params[:held_ms]
    )
    @night.broadcast_state(pulse: { kind: "pose", player: current_player })
    head :ok
  rescue RuntimeError, ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    head :unprocessable_entity
  end
end
