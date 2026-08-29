require "test_helper"

class ChurchVideosControllerTest < ActionDispatch::IntegrationTest
  teardown do
    ChurchVideos::Catalog.forced_result = nil
  end

  test "shows the localized official catalog and keeps playback inside a consent dialog" do
    ChurchVideos::Catalog.forced_result = successful_catalog

    get church_videos_path(locale: "fr")

    assert_response :success
    assert_select "body.is-church-videos.is-celestial-dark"
    assert_select ".church-video-world[data-controller=church-video]"
    assert_select ".church-video-hero h1", text: I18n.t("church_videos.title", locale: :fr)
    assert_select ".church-video-channel", text: /Église officielle/
    assert_select "form.church-video-search[role=search]"
    assert_select "input[type=search][name=q]"
    assert_select ".church-video-playlist", count: 5
    assert_select ".church-video-playlist.is-featured", count: 3
    assert_select ".church-video-playlist:first-child.is-featured strong", text: "Vidéos sur la Bible"
    assert_select ".church-video-playlist:nth-child(2).is-featured strong", text: "Levez-vous et brillez"
    assert_select ".church-video-playlist:nth-child(3).is-featured strong", text: "Histoires du Livre de Mormon"
    assert_select ".church-video-playlist-featured", text: I18n.t("church_videos.featured_playlist", locale: :fr), count: 3
    assert_select ".church-video-playlist:nth-child(4).is-active strong", text: I18n.t("church_videos.all_videos", locale: :fr)
    assert_select ".chrome-tools", count: 0
    assert_select ".chrome-drawer .mute", count: 1
    assert_select ".chrome-drawer .lang-switch.is-drawer", count: 1
    assert_select ".church-video-card", count: 1
    assert_select "button.church-video-trigger[data-video-id=abc123DEF_4]"
    assert_select "img[src=?]", church_video_thumbnail_path("abc123DEF_4")
    assert_select ".church-video-duration", text: "3:03"
    assert_select "iframe", count: 0
    assert_select "dialog.church-video-dialog"
    assert_select ".church-video-consent .btn-gold", text: I18n.t("church_videos.accept_and_watch", locale: :fr)
    assert_select "meta[http-equiv='Content-Security-Policy'][content*='youtube-nocookie.com']", visible: false
    assert_select "nav.navigation-dock .navigation-dock__item", count: 5
    assert_select ".navigation-dock__item.is-active[href=?]", church_path
  end

  test "shows a graceful local state when YouTube is unavailable" do
    ChurchVideos::Catalog.forced_result = ChurchVideos::Catalog::Result.new(channel: nil, videos: [], error: :not_configured)

    get church_videos_path

    assert_response :success
    assert_select ".church-video-empty.is-error"
    assert_select ".church-video-empty h2", text: I18n.t("church_videos.unavailable_title")
    assert_select "a.church-video-back[href=?]", root_path(locale: I18n.locale)
  end

  test "the home tile is local artwork and never embeds YouTube" do
    get root_path

    assert_response :success
    assert_select "a.hub-videos[href*='/videos']"
    assert_select ".hub-videos picture img[src^='/media/generated/']"
    assert_select ".hub-videos .picto-video-library"
    assert_select "iframe[src*='youtube']", count: 0
  end

  private

    def successful_catalog
      channel = ChurchVideos::Catalog::Channel.new(
        id: "UC-official",
        title: "Église officielle",
        description: "Chaîne officielle",
        uploads_playlist_id: "UU-official",
        public_url: "https://www.youtube.com/channel/UC-official"
      )
      video = ChurchVideos::Catalog::Video.new(
        id: "abc123DEF_4",
        title: "Une histoire d’espérance",
        description: "",
        published_at: Time.utc(2026, 8, 20, 12, 30),
        duration_seconds: 183,
        made_for_kids: false
      )
      playlists = [
        [ "PLK-wt8EdZqtnl0iP3wyFWACLAFbMaejYf", "Vidéos sur la Bible", 51, true ],
        [ "PL8E1F2F1CBE58946A", "Levez-vous et brillez", 19, true ],
        [ "PLC8EAFACE59892017", "Histoires du Livre de Mormon", 54, true ],
        [ "PL-not-featured-01", "Messages de paix", 8, false ]
      ].map do |id, title, video_count, featured|
        ChurchVideos::Catalog::Playlist.new(
          id:,
          title:,
          description: "Collection officielle",
          video_count:,
          thumbnail_video_id: video.id,
          featured:
        )
      end
      ChurchVideos::Catalog::Result.new(
        channel:,
        playlists:,
        active_playlist: nil,
        query: nil,
        videos: [ video ],
        next_page_token: "NEXT_PAGE",
        error: nil
      )
    end
end
