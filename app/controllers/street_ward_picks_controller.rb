class StreetWardPicksController < ApplicationController
  def create
    ward = Wards::Enter.call(code: params[:code])
    remember_ward(ward)
    redirect_to root_path
  rescue People::Error => error
    redirect_to root_path, alert: error.message
  end
end
