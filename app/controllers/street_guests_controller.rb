class StreetGuestsController < ApplicationController
  def create
    remember_street_guest
    redirect_to root_path, notice: I18n.t("flashes.street_guest_ready")
  end
end
