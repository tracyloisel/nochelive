class WardGatesController < ApplicationController
  def show
  end

  def create
    ward = Wards::Open.call(code: params[:code], token: params[:token])
    remember_ward_admin(ward)
    redirect_to ward_profile_path(ward.code)
  rescue People::Error => error
    flash.now[:alert] = error.message
    render :show, status: :unprocessable_entity
  end
end
