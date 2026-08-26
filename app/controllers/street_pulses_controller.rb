class StreetPulsesController < ApplicationController
  def show
    expires_now
    @pulse = Platform::Pulse.call
    render layout: false
  end
end
