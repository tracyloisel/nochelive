class PresencesController < ApplicationController
  rescue_from ActionController::InvalidAuthenticityToken, with: :quiet_heartbeat
  before_action :set_night, :require_player

  def create
    Presences::Heartbeat.call(player: current_player)
    head :no_content
  end

  private

    def quiet_heartbeat
      head :no_content
    end
end
