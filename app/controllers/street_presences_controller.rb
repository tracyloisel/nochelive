class StreetPresencesController < ApplicationController
  def create
    remember_device
    person = current_street_person
    Presences::StreetHeartbeat.call(person:, device_token: device_token) if person
    head :no_content
  end
end
