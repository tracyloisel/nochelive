class ScriptureCircleModerationHistoriesController < ApplicationController
  def show
    @history = ScriptureCircles::Moderations::History.call(
      person: current_street_person,
      proposal_id: params[:proposal_id]
    )
  rescue ScriptureCircles::Access::Error, ActiveRecord::RecordNotFound
    head :forbidden
  end
end
