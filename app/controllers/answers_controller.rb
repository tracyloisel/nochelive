class AnswersController < ApplicationController
  before_action :set_night, :require_player, :require_team

  def create
    @round = @night.round_runs.find(params[:round_run_id])
    body = params[:body].presence || params[:choice].to_s
    @answer = Answers::Submit.call(round: @round, team: current_team, player: current_player, body:)
    Rails.logger.info("session=#{@night.code} round=#{@round.yaml_round_id} team=#{current_team.id} event=answer")
    respond_to do |format|
      format.turbo_stream do
        if @round.definition.choice?
          @team = current_team.reload
          @player = current_player
          render :create
        else
          redirect_to night_play_path(@night.code)
        end
      end
      format.html { redirect_to night_play_path(@night.code) }
    end
  rescue RuntimeError, ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    redirect_to night_play_path(@night.code)
  end
end
