class ViralEventsController < ApplicationController
  include StreetQuiz

  protect_from_forgery with: :null_session

  def create
    duel = StreetDuel.find_by(token: params[:duel_token])
    Quizzes::ViralTrack.call(
      name: params[:name],
      device_digest: street_digest,
      duel:,
      person: current_street_person,
      source: params[:source],
      properties: params.permit(properties: {}).fetch(:properties, {})
    )
    head :no_content
  rescue ActiveRecord::RecordInvalid, ActionController::ParameterMissing
    head :unprocessable_entity
  end
end
