require "test_helper"

class ChurchVideos::ThumbnailTest < ActiveSupport::TestCase
  setup do
    @cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    ChurchVideos::Thumbnail.fetcher = nil
  end

  test "proxies a fixed YouTube thumbnail host and caches the image" do
    requests = []
    ChurchVideos::Thumbnail.fetcher = lambda do |uri|
      requests << uri
      ChurchVideos::Thumbnail::Image.new(body: "jpeg-data", content_type: "image/jpeg")
    end

    2.times do
      image = ChurchVideos::Thumbnail.call(video_id: "abc123DEF_4", cache: @cache)
      assert_equal "jpeg-data", image.body
    end

    assert_equal 1, requests.size
    assert_equal "i.ytimg.com", requests.first.host
    assert_equal "/vi/abc123DEF_4/mqdefault.jpg", requests.first.path
  end

  test "rejects anything that is not an eleven-character video id" do
    called = false
    ChurchVideos::Thumbnail.fetcher = ->(*) { called = true }

    assert_nil ChurchVideos::Thumbnail.call(video_id: "../../secrets", cache: @cache)
    refute called
  end

  test "caches a remote failure briefly" do
    calls = 0
    ChurchVideos::Thumbnail.fetcher = ->(*) { calls += 1; raise Net::ReadTimeout }

    2.times { assert_nil ChurchVideos::Thumbnail.call(video_id: "abc123DEF_4", cache: @cache) }

    assert_equal 1, calls
  end
end
