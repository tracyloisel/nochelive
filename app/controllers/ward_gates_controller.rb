class WardGatesController < ApplicationController
  def show
  end

  def create
    ward = Wards::Open.call(code: params[:code], token: params[:token])
    remember_ward(ward)
    redirect_to new_game_session_path
  rescue People::Error => error
    flash.now[:alert] = error.message
    render :show, status: :unprocessable_entity
  end
end
