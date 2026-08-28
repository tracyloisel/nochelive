class StreetPulsesController < ApplicationController
  def show
    expires_in 15.seconds, public: true
    @pulse = Platform::Pulse.call
    render layout: false
  end
end
