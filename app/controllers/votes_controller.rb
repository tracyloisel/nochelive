class VotesController < ApplicationController
  before_action :set_night, :require_player, :require_team

  def create
    round = @night.round_runs.find(params[:round_run_id])
    choice = @night.teams.find(params[:team_id])
    Votes::Cast.call(round:, team: current_team, player: current_player, choice:)
    Rails.logger.info("session=#{@night.code} round=#{round.yaml_round_id} player=#{current_player.id} event=vote")
    redirect_to night_play_path(@night.code)
  rescue RuntimeError, ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound
    redirect_to night_play_path(@night.code)
  end
end
