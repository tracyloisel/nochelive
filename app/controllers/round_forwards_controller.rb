class RoundForwardsController < ApplicationController
  before_action :set_night, :require_player, :require_team

  def create
    # Compatibility endpoint for clients that still render the former
    # "Siguiente" control. Participants never advance the shared stage:
    # presenter timing is authoritative for room, Casa, Public and TV.
    respond_to do |format|
      format.turbo_stream { head :no_content }
      format.html { redirect_to night_play_path(@night.code) }
    end
  end
end
