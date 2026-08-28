class ChurchVideosController < ApplicationController
  def index
    remember_device
    @artwork = ChurchVideos::Catalog.artwork
    @catalog = ChurchVideos::Catalog.call(
      locale: I18n.locale,
      page_token: params[:page],
      playlist_id: params[:playlist],
      query: params[:q]
    )
  end
end
