class ChurchVideoThumbnailsController < ApplicationController
  def show
    image = ChurchVideos::Thumbnail.call(video_id: params[:id])
    return head :not_found unless image

    expires_in ChurchVideos::Thumbnail::HIT_TTL, public: true
    send_data image.body, type: image.content_type, disposition: "inline"
  end
end
