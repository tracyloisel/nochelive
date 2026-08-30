class ScriptureCircleModerationResultsController < ApplicationController
  def show
    render json: ScriptureCircles::Moderations::LiveResults.call(
      person: current_street_person,
      proposal_id: params[:proposal_id]
    )
  rescue ScriptureCircles::Access::Error, ActiveRecord::RecordNotFound
    head :forbidden
  end
end
