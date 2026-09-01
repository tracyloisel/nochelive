require "test_helper"

class HubVideoHighlightsControllerTest < ActionDispatch::IntegrationTest
  teardown do
    ChurchVideos::Catalog.forced_result = nil
  end

  test "the initial Home response references a lazy frame without loading the catalog" do
    catalog_calls = 0
    catalog_class = ChurchVideos::Catalog.singleton_class
    trace = TracePoint.new(:call) do |event|
      catalog_calls += 1 if event.defined_class.equal?(catalog_class) && event.method_id == :call
    end

    trace.enable do
      get root_path(locale: "fr")
    end
    trace.disable

    assert_response :success
    assert_equal 0, catalog_calls
    assert_select "turbo-frame#hub_watch_rail.hub-watch-frame[src=?][loading='lazy']",
      hub_video_highlights_path(locale: :fr),
      count: 1
    assert_select "turbo-frame#hub_watch_rail .hub-content-card", count: 0
    assert_select "img[src*='/videos/miniatures/']", count: 0
  ensure
    trace&.disable
  end

  test "renders at most six real videos with local lazy thumbnails and exact catalog anchors" do
    videos = 8.times.map { |index| video(format("video%06d", index), title: "Histoire #{index}") }
    ChurchVideos::Catalog.forced_result = result(videos:)

    get hub_video_highlights_path(locale: "fr"), headers: { "Turbo-Frame" => "hub_watch_rail" }

    assert_response :success
    assert_select "turbo-frame#hub_watch_rail", count: 1 do
      assert_select "section.hub-content-rail.hub-watch-rail", count: 1
      assert_select "h2#hub-watch-rail-title", text: I18n.t("hub.rails.watch", locale: :fr)
      assert_select ".hub-content-card--video", count: 6
      assert_select "a.hub-content-card__link[data-turbo-frame='_top']", count: 6
      assert_select "a.hub-content-card__link[href=?]",
        church_videos_path(locale: :fr, anchor: "video-video000000"),
        text: /Histoire 0/,
        count: 1
      assert_select "a.hub-content-card__link[aria-label=?]",
        I18n.t("church_videos.watch", title: "Histoire 0", locale: :fr),
        count: 1
      assert_select "img[src=?][loading='lazy'][decoding='async'][width='320'][height='180']",
        church_video_thumbnail_path("video000000"),
        count: 1
      assert_select ".hub-content-card__play .picto-play", count: 6
      assert_select ".hub-content-card__play .picto-play circle", count: 6
      assert_select ".hub-content-card__play .picto-play path", count: 6
      assert_select ".hub-content-card__duration", text: "3:03", count: 6
      assert_select "time[datetime='2026-08-20T12:30:00Z']", count: 6
    end
    assert_select "iframe", count: 0
    refute_includes response.body, "i.ytimg.com"
    refute_includes response.body, "youtube.com"
  end

  test "renders only an empty matching frame when the catalog is unavailable or empty" do
    [ :not_configured, :unavailable, nil ].each do |error|
      ChurchVideos::Catalog.forced_result = result(videos: [], error:)

      get hub_video_highlights_path, headers: { "Turbo-Frame" => "hub_watch_rail" }

      assert_response :success
      assert_select "turbo-frame#hub_watch_rail", count: 1 do
        assert_select "section", count: 0
        assert_select ".hub-content-card", count: 0
        assert_select ".hub-content-card__play, .hub-content-rail__head", count: 0
      end
    end
  end

  private

    def result(videos:, error: nil)
      ChurchVideos::Catalog::Result.new(videos:, error:)
    end

    def video(id, title:)
      ChurchVideos::Catalog::Video.new(
        id:,
        title:,
        description: "",
        published_at: Time.utc(2026, 8, 20, 12, 30),
        duration_seconds: 183,
        made_for_kids: false
      )
    end
end
