class RoundForwardsController < ApplicationController
  before_action :set_night, :require_player, :require_team

  def create
    round = @night.round_runs.find(params[:round_run_id])
    Rounds::Forward.call(round:, team: current_team)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "night_play",
          partial: "play/frame",
          locals: { night: @night.reload, team: current_team.reload, player: current_player }
        )
      end
      format.html { redirect_to night_play_path(@night.code) }
    end
  rescue RuntimeError
    redirect_to night_play_path(@night.code)
  end
end
