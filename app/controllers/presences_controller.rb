class PresencesController < ApplicationController
  before_action :set_night, :require_player

  def create
    Presences::Heartbeat.call(player: current_player)
    head :no_content
  end
end
