class ViralEventsController < ApplicationController
  include StreetQuiz

  protect_from_forgery with: :null_session

  def create
    invitation = DuelInvitation.find_by_token(params[:duel_token])
    duel = invitation&.street_duel
    if params[:name] == "invite_share_handoff" && invitation
      Quizzes::DuelInvitationReceipt.call(
        invitation:,
        state: :share_handoff,
        person: current_street_person,
        device_digest: street_digest,
        source: params[:source],
        channel: params.dig(:properties, :channel)
      )
      head :no_content
      return
    end

    Quizzes::ViralTrack.call(
      name: params[:name],
      device_digest: street_digest,
      duel:,
      invitation:,
      person: current_street_person,
      source: params[:source],
      properties: params.permit(properties: {}).fetch(:properties, {})
    )
    head :no_content
  rescue ActiveRecord::RecordInvalid, ActionController::ParameterMissing
    head :unprocessable_entity
  end
end
