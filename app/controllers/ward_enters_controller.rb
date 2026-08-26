class WardEntersController < ApplicationController
  def create
    ward = Wards::Enter.call(code: params[:code], church_unit_id: params[:church_unit_id])
    remember_ward(ward)
    redirect_to ward_profile_path(ward.code)
  rescue People::Error => error
    redirect_to search_path, alert: error.message
  end
end
