class SearchesController < ApplicationController
  def show
    @query = params[:q].to_s
    @changing_ward = params[:cambiar].present?
    @pick_url = street_pick? ? street_ward_pick_path : enter_ward_path
    @search = Wards::Search.call(
      query: @query,
      latitude: params[:lat],
      longitude: params[:lng]
    )
    @wards = @search.wards

    render "searches/frame", layout: false if turbo_frame_request?
  end

  private

    def street_pick?
      @changing_ward || params[:pick].to_s == "rama"
    end
end
