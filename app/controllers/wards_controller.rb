class WardsController < ApplicationController
  def new
    @ward = current_ward
  end

  def create
    ward = Wards::Create.call(name: params.require(:name))
    remember_ward(ward)
    Rails.logger.info("ward=#{ward.code} event=created")
    redirect_to new_game_session_path
  rescue People::Error => error
    flash.now[:alert] = error.message
    render :new, status: :unprocessable_entity
  end
end
