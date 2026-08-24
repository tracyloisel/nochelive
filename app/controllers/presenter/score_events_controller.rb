module Presenter
  class ScoreEventsController < ApplicationController
    before_action :set_night, :require_presenter

    def create
      team = @night.teams.find(params[:team_id])
      round = @night.round_runs.find_by(id: params[:round_run_id])

      case params[:kind]
      when "correct"
        Scores::Apply.correct!(round, team, broadcast: false)
      when "incorrect"
        Scores::Apply.incorrect!(round, team, broadcast: false)
      when "plus"
        Scores::Apply.adjust!(@night, team, points: 5, reason: "Ajuste del presentador +5", broadcast: false)
      when "minus"
        Scores::Apply.adjust!(@night, team, points: -5, reason: "Ajuste del presentador −5", broadcast: false)
      end
      @night.broadcast_state(pulse: { kind: "score", label: team.name })

      Rails.logger.info("session=#{@night.code} team=#{team.id} event=score kind=#{params[:kind]}")
      redirect_to presenter_console_path(@night.code)
    end
  end
end
