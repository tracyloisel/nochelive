class StreetPulsesController < ApplicationController
  def show
    expires_in Platform::Pulse::CACHE_TTL, public: true
    @pulse = Platform::Pulse.call
    render layout: false
  end
end
