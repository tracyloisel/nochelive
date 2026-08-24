class BuzzesController < ApplicationController
  before_action :set_night, :require_player, :require_team

  def create
    round = @night.round_runs.find(params[:round_run_id])
    buzz = Buzzes::Accept.call(round_run: round, team: current_team, player: current_player)
    Rails.logger.info("session=#{@night.code} round=#{round.yaml_round_id} player=#{current_player.id} team=#{current_team.id} event=buzz position=#{buzz.position} latency_ms=#{buzz.latency_ms}")
    pulse = if buzz.previously_new_record?
      { kind: "buzz", player: current_player, delay_ms: buzz.latency_ms, place: buzz.position }
    end
    @night.broadcast_state(pulse: pulse)
    redirect_to night_play_path(@night.code)
  rescue RuntimeError, ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    @night.broadcast_state
    redirect_to night_play_path(@night.code)
  end
end
