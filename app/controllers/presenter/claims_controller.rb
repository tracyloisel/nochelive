module Presenter
  class ClaimsController < ApplicationController
    before_action :set_night
    before_action :require_presenter, only: :resolve

    def show
      claim = latest_claim
      unless claim
        redirect_to presenter_gate_path(@night.code)
        return
      end

      Presenters::Expire.call(claim: claim)
      claim.reload
      @night.reload

      if claim.granted? || @night.presenter_held_by?(device_token)
        remember_presenter(@night)
        remember_ward(@night.ward)
        redirect_to presenter_console_path(@night.code)
        return
      end

      @claim = claim
    end

    def create
      outcome = Presenters::Claim.call(night: @night, device_token: device_token, name: claimant_name)
      if outcome == :seated
        remember_presenter(@night)
        remember_ward(@night.ward)
        redirect_to presenter_console_path(@night.code)
      else
        redirect_to presenter_claim_path(@night.code)
      end
    rescue People::Error => error
      redirect_to presenter_gate_path(@night.code), alert: error.message
    end

    def resolve
      claim = @night.presenter_claims.find(params[:id])
      Presenters::Resolve.call(
        night: @night,
        claim: claim,
        decision: params[:decision].to_s,
        holder_token: device_token
      )
      if params[:decision].to_s == "grant"
        redirect_to presenter_gate_path(@night.code), notice: "Cediste la mesa."
      else
        redirect_to presenter_console_path(@night.code)
      end
    rescue People::Error => error
      redirect_to presenter_console_path(@night.code), alert: error.message
    end

    private

      def latest_claim
        @night.presenter_claims.where(device_digest: GameSession.digest_token(device_token)).order(:id).last
      end

      def claimant_name
        person = people_on_device.first
        (person&.display_name.presence || current_player&.name.presence || "Alguien")
      end
  end
end
