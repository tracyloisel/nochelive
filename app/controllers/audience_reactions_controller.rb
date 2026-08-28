class AudienceReactionsController < ApplicationController
  before_action :set_public_night

  def create
    round = @night.round_runs.find(params[:round_run_id])
    Audience::React.call(
      night: @night,
      round: round,
      audience_digest: audience_digest,
      mark: params[:mark]
    )
    redirect_to night_public_path(@night.public_token), status: :see_other
  rescue Audience::React::Closed, Audience::React::RateLimited, ActiveRecord::RecordInvalid
    redirect_to night_public_path(@night.public_token), status: :see_other
  end

  private

    def set_public_night
      @night = GameSession.find_by!(public_token: params[:public_token])
    end
end
