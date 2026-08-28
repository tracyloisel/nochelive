class AudienceResponsesController < ApplicationController
  before_action :set_public_night

  def create
    round = @night.round_runs.find(params[:round_run_id])
    Audience::Respond.call(
      night: @night,
      round: round,
      audience_digest: audience_digest,
      choice: params[:choice]
    )
    redirect_to night_public_path(@night.public_token), status: :see_other
  rescue Audience::Respond::Closed
    redirect_to night_public_path(@night.public_token), alert: I18n.t("audience.closed"), status: :see_other
  rescue Audience::Respond::InvalidChoice
    redirect_to night_public_path(@night.public_token), alert: I18n.t("audience.invalid_choice"), status: :see_other
  end

  private

    def set_public_night
      @night = GameSession.find_by!(public_token: params[:public_token])
    end
end
