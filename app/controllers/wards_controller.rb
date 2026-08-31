class WardsController < ApplicationController
  def new
    @ward = Ward.new
  end

  def create
    ward = Wards::Create.call(
      name: params[:name],
      emblem: params[:emblem],
      chapel_name: params[:chapel_name],
      chapel_address: params[:chapel_address],
      city: params[:city],
      region: params[:region],
      postal_code: params[:postal_code],
      country_code: params[:country_code]
    )
    remember_ward_admin(ward)
    Rails.logger.info("ward=#{ward.code} event=created")
    redirect_to ward_profile_path(ward.code)
  rescue People::Error => error
    flash.now[:alert] = error.message
    @ward = Ward.new
    render :new, status: :unprocessable_entity
  end
end
