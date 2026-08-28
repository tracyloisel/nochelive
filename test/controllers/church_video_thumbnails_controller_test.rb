require "test_helper"

class ChurchVideoThumbnailsControllerTest < ActionDispatch::IntegrationTest
  teardown do
    ChurchVideos::Thumbnail.forced_response = nil
  end

  test "serves a cached-safe image without redirecting the browser to Google" do
    ChurchVideos::Thumbnail.forced_response = ChurchVideos::Thumbnail::Image.new(body: "jpeg-data", content_type: "image/jpeg")

    get church_video_thumbnail_path("abc123DEF_4")

    assert_response :success
    assert_equal "image/jpeg", response.media_type
    assert_equal "jpeg-data", response.body
    assert_match(/max-age=1800/, response.headers["Cache-Control"])
  end

  test "returns not found when a thumbnail cannot be loaded" do
    ChurchVideos::Thumbnail.forced_response = false
    get church_video_thumbnail_path("abc123DEF_4")

    assert_response :not_found
  end
end
