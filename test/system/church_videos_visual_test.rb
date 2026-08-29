require "application_system_test_case"

class ChurchVideosVisualTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/street-shots/temple-mockups")

  setup do
    ChurchVideos::Catalog.forced_result = catalog
    artwork = Rails.root.join("media/masters/media/church/videos/celestial-video-sanctuary-v1.webp").binread
    ChurchVideos::Thumbnail.forced_response = ChurchVideos::Thumbnail::Image.new(body: artwork, content_type: "image/webp")
  end

  teardown do
    ChurchVideos::Catalog.forced_result = nil
    ChurchVideos::Thumbnail.forced_response = nil
  end

  test "video sanctuary reads on phone, consent gate, and desktop" do
    set_system_viewport(390, 844)
    visit church_videos_path(locale: "es")
    assert_selector "html[lang=es]"
    assert_selector ".church-video-card", count: 8
    assert_selector ".church-video-search"
    assert_selector ".church-video-playlist", minimum: 6
    assert_selector ".church-video-playlist.is-featured", count: 4
    assert_selector ".church-video-playlist:first-child.is-featured .church-video-playlist-featured"
    assert_selector ".church-video-playlist:nth-child(5).is-active"
    assert_no_selector ".chrome-tools"
    assert_selector ".chrome-drawer .mute", visible: :all
    assert_selector ".chrome-drawer .lang-switch.is-drawer", visible: :all
    assert_no_selector "iframe"
    assert_equal 1, grid_column_count
    shot("mockup-church-videos-mobile")

    find(".home-menu-btn").click
    assert_selector ".chrome-drawer[open] .mute"
    assert_selector ".chrome-drawer[open] .lang-switch.is-drawer"
    shot("mockup-church-videos-menu")
    find(".chrome-drawer").send_keys(:escape)
    assert_no_selector ".chrome-drawer[open]"

    scroll_to find(".church-video-playlists"), align: :top
    shot("mockup-church-videos-featured-playlist")

    first(".church-video-trigger").click
    assert_selector ".church-video-dialog[open] .church-video-consent"
    assert_no_selector ".church-video-dialog iframe"
    shot("mockup-church-videos-consent")

    click_button I18n.t("church_videos.accept_and_watch", locale: :es)
    assert_selector ".church-video-dialog iframe[src*='youtube-nocookie.com']"
    shot("mockup-church-videos-player")

    find(".church-video-dialog-close").click
    assert_no_selector ".church-video-dialog[open]"
    set_system_viewport(1000, 900)
    assert_selector ".church-video-grid"
    assert_equal 3, grid_column_count
    set_system_viewport(1900, 1000)
    assert_selector ".church-video-grid"
    assert_equal 5, grid_column_count
    set_system_viewport(1280, 900)
    assert_selector ".church-video-grid"
    page.execute_script("window.scrollTo(0, 0)")
    assert_equal 4, grid_column_count
    shot("mockup-church-videos-desktop")
  end

  test "home keeps the official video door secondary and fully local" do
    set_system_viewport(390, 844)
    visit root_path(locale: "fr")
    page.execute_script(<<~JS)
      document.querySelector("#profile_gate")?.remove()
      document.querySelector("#street_world")?.classList.remove("is-profile-gate")
    JS
    assert_selector ".hub-videos"
    assert_selector ".hub-videos img[src*='/media/generated/catalog/church/videos/celestial-video-sanctuary-v1/']"
    assert_no_selector ".hub-videos iframe"
    scroll_to find(".hub-videos"), align: :center
    shot("mockup-hub-official-videos-tile")
  end

  private

    def catalog
      channel = ChurchVideos::Catalog::Channel.new(
        id: "UC-official",
        title: "Iglesia de Jesucristo",
        description: "Chaîne officielle",
        uploads_playlist_id: "UU-official",
        public_url: "https://www.youtube.com/channel/UC-official"
      )
      ids = %w[abc123DEF_4 XYZ987ghi_2 Hope12345_A Light9876_B Faith1234_C Home12345_D Serve1234_E Music1234_F]
      titles = [
        "Trouver la paix quand tout va trop vite",
        "Une famille choisit de servir ensemble",
        "La foi commence par une petite lumière",
        "Un message d’espérance pour aujourd’hui",
        "Chanter ensemble à la maison",
        "Pourquoi Jésus-Christ est au centre",
        "Des jeunes transforment leur quartier",
        "Une minute pour respirer et prier"
      ]
      videos = ids.zip(titles).map.with_index do |(id, title), index|
        ChurchVideos::Catalog::Video.new(
          id:,
          title:,
          description: "",
          published_at: Time.utc(2026, 8, 20 - index, 12, 30),
          duration_seconds: 185 + index * 47,
          made_for_kids: false
        )
      end
      playlists = [
        [ "PL27339DE7B0837012", "Videos de la Bíblia", 104 ],
        [ "PLFDD05D13D74978D0", "Levantaos y brillad", 18 ],
        [ "PLD68DBD93671935E7", "Historias del Libro de Mormón", 54 ],
        [ "PL75AE9E0550DBAD93", "Videos Especiales", 14 ],
        [ "PL-not-featured-01", "Mensajes de paz", 8 ]
      ].map.with_index do |(id, title, video_count), index|
        ChurchVideos::Catalog::Playlist.new(
          id:,
          title:,
          description: "Collection officielle",
          video_count:,
          thumbnail_video_id: ids[index],
          featured: index < 4
        )
      end
      ChurchVideos::Catalog::Result.new(
        channel:,
        playlists:,
        active_playlist: nil,
        query: nil,
        videos:,
        error: nil
      )
    end

    def shot(name)
      FileUtils.mkdir_p(SHOT_DIR)
      path = SHOT_DIR.join("#{name}.png")
      page.save_screenshot(path)
      warn "church-video-shot #{path}"
    end

    def grid_column_count
      page.evaluate_script("getComputedStyle(document.querySelector('.church-video-grid')).gridTemplateColumns.split(' ').length")
    end
end
