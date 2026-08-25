class CheersController < ApplicationController
  before_action :set_night, :require_player, :require_team

  def create
    round = @night.round_runs.find(params[:round_run_id])
    to_player = @night.players.participants.find(params[:to_player_id])
    Cheers::Send.call(night: @night, player: current_player, to_player:)
    Rails.logger.info("session=#{@night.code} round=#{round.yaml_round_id} player=#{current_player.id} event=cheer")
    redirect_to night_play_path(@night.code)
  rescue RuntimeError, ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound
    redirect_to night_play_path(@night.code)
  end
end
