class StreetWardPicksController < ApplicationController
  def create
    ward = Wards::Enter.call(code: params[:code], church_unit_id: params[:church_unit_id])
    person = current_street_person
    if person
      People::Transfer.call(person:, ward:)
      remember_ward(ward)
      redirect_to root_path, notice: I18n.t("flashes.street_ward_changed", ward: ward.name)
    else
      remember_ward(ward)
      redirect_to root_path
    end
  rescue People::Error => error
    redirect_to search_path(cambiar: 1), alert: error.message
  end
end
