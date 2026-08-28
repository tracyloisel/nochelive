require "test_helper"
require "cgi"

class ChurchVideos::CatalogTest < ActiveSupport::TestCase
  setup do
    @cache = ActiveSupport::Cache::MemoryStore.new
    @requests = []
  end

  teardown do
    ChurchVideos::Catalog.transport = nil
  end

  test "loads the localized official channel and keeps only public embeddable videos" do
    ChurchVideos::Catalog.transport = method(:youtube_response)

    result = ChurchVideos::Catalog.call(locale: :es, cache: @cache, api_key: "secret")

    assert result.available?
    assert_equal "Iglesia de Jesucristo", result.channel.title
    assert_equal "https://www.youtube.com/@IglesiadeJesucristoESP", result.channel.public_url
    assert_equal [
      "PL27339DE7B0837012",
      "PLFDD05D13D74978D0",
      "PLD68DBD93671935E7",
      "PL75AE9E0550DBAD93",
      "PL-not-featured-01"
    ], result.playlists.map(&:id)
    assert_equal "Videos de la Bíblia", result.playlists.first.title
    assert_equal 104, result.playlists.first.video_count
    assert_equal "thumb1234_A", result.playlists.first.thumbnail_video_id
    assert result.playlists.first(4).all?(&:featured)
    refute result.playlists.last.featured
    assert_equal [ "abc123DEF_4" ], result.videos.map(&:id)
    assert_equal "Una historia de esperanza", result.videos.first.title
    assert_equal 3723, result.videos.first.duration_seconds
    assert result.videos.first.made_for_kids
    assert_equal "NEXT_PAGE", result.next_page_token
    assert_equal "PREV_PAGE", result.previous_page_token

    channel_query = query_for("/youtube/v3/channels")
    assert_equal [ "@IglesiadeJesucristoESP" ], channel_query["forHandle"]
    refute channel_query.key?("id")
    assert_equal [ "secret" ], channel_query["key"]
    assert_equal [ "UC-official" ], query_for("/youtube/v3/playlists")["channelId"]
  end

  test "opens only a playlist that belongs to the localized official channel" do
    ChurchVideos::Catalog.transport = method(:youtube_response)

    result = ChurchVideos::Catalog.call(
      locale: :es,
      playlist_id: "PL27339DE7B0837012",
      cache: @cache,
      api_key: "secret"
    )

    assert_equal "PL27339DE7B0837012", result.active_playlist.id
    assert_equal [ "PL27339DE7B0837012" ], query_for("/youtube/v3/playlistItems")["playlistId"]
  end

  test "searches videos only inside the localized official channel" do
    ChurchVideos::Catalog.transport = method(:youtube_response)

    result = ChurchVideos::Catalog.call(locale: :es, query: "  esperanza  ", cache: @cache, api_key: "secret")

    assert result.available?
    assert_equal "esperanza", result.query
    assert_nil result.active_playlist
    assert_equal [ "abc123DEF_4" ], result.videos.map(&:id)
    query = query_for("/youtube/v3/search")
    assert_equal [ "UC-official" ], query["channelId"]
    assert_equal [ "esperanza" ], query["q"]
    assert_equal [ "video" ], query["type"]
    assert_equal [ "true" ], query["videoEmbeddable"]
    assert_equal [ "es" ], query["relevanceLanguage"]
  end

  test "ignores a playlist id that is not returned by the official channel" do
    ChurchVideos::Catalog.transport = method(:youtube_response)

    result = ChurchVideos::Catalog.call(
      locale: :es,
      playlist_id: "PL-foreign-999",
      cache: @cache,
      api_key: "secret"
    )

    assert_nil result.active_playlist
    assert_equal [ "UU-official" ], query_for("/youtube/v3/playlistItems")["playlistId"]
  end

  test "exposes the artwork-driven Celestial Dark manifest" do
    artwork = ChurchVideos::Catalog.artwork

    assert_equal "/media/church/videos/celestial-video-sanctuary-v1.webp", artwork.fetch("src")
    assert_equal "dark", artwork.dig("theme", "mode")
    assert_equal "sanctuary", artwork.dig("theme", "atmosphere")
  end

  test "pins one official Church channel per supported locale" do
    channels = ChurchVideos::Catalog.configuration.fetch("channels")

    assert_equal Locale::AVAILABLE.sort, channels.keys.sort
    assert_equal "@IglesiadeJesucristoESP", channels.dig("es", "for_handle")
    assert_equal "@IgrejadeJesusCristoPOR", channels.dig("pt-BR", "for_handle")
    assert_equal "UC3CbfUXOgoOsD7srESW98mA", channels.dig("fr", "id")
    assert_equal "@churchofjesuschrist", channels.dig("en", "for_handle")
  end

  test "pins the curated localized playlists with Bible first" do
    featured = ChurchVideos::Catalog.configuration.fetch("featured_playlists")

    assert_equal Locale::AVAILABLE.sort, featured.keys.sort
    assert_equal %w[
      PL27339DE7B0837012
      PLFDD05D13D74978D0
      PLD68DBD93671935E7
      PL75AE9E0550DBAD93
    ], featured.fetch("es")
    assert_equal %w[
      PL31F32E21D67DE8AE
      PLDCD6C70A45E2CCDF
      PLE6604AE46FC911FF
      PLs6Xki82zjab0ZyJ1O6KQpedX-dM_NMzM
    ], featured.fetch("pt-BR")
    assert_equal %w[
      PLK-wt8EdZqtnl0iP3wyFWACLAFbMaejYf
      PL8E1F2F1CBE58946A
      PLC8EAFACE59892017
    ], featured.fetch("fr")
    assert_equal %w[
      PL4A73DDEE675FBC39
      PL9B0692E0D672DC72
    ], featured.fetch("en")
  end

  test "uses the stable channel id for French" do
    ChurchVideos::Catalog.transport = method(:youtube_response)

    result = ChurchVideos::Catalog.call(locale: :fr, cache: @cache, api_key: "secret")

    assert result.available?
    assert_equal [ "UC3CbfUXOgoOsD7srESW98mA" ], query_for("/youtube/v3/channels")["id"]
    refute query_for("/youtube/v3/channels").key?("forHandle")
  end

  test "caches a complete page and never exposes the api key in its cache key" do
    ChurchVideos::Catalog.transport = method(:youtube_response)

    2.times { ChurchVideos::Catalog.call(locale: :en, cache: @cache, api_key: "do-not-cache") }

    assert_equal 4, @requests.size
    keys = @cache.instance_variable_get(:@data).keys.map(&:to_s)
    refute keys.any? { |key| key.include?("do-not-cache") }
  end

  test "returns a clear unavailable result when the api key is absent" do
    called = false
    ChurchVideos::Catalog.transport = ->(*) { called = true }

    result = ChurchVideos::Catalog.call(locale: :es, cache: @cache, api_key: "")

    refute result.available?
    assert_equal :not_configured, result.error
    assert_empty result.videos
    refute called
  end

  test "caches a timeout briefly instead of hammering YouTube" do
    calls = 0
    ChurchVideos::Catalog.transport = ->(*) { calls += 1; raise Net::OpenTimeout }

    2.times do
      result = ChurchVideos::Catalog.call(locale: :es, cache: @cache, api_key: "secret")
      assert_equal :unavailable, result.error
    end

    assert_equal 1, calls
  end

  test "drops an invalid pagination token" do
    ChurchVideos::Catalog.transport = method(:youtube_response)

    ChurchVideos::Catalog.call(locale: :es, page_token: "bad token!", cache: @cache, api_key: "secret")

    refute query_for("/youtube/v3/playlistItems").key?("pageToken")
  end

  private

    def youtube_response(uri)
      @requests << uri
      case uri.path
      when "/youtube/v3/channels"
        {
          items: [ {
            id: "UC-official",
            snippet: { title: "Iglesia de Jesucristo", description: "Canal oficial" },
            contentDetails: { relatedPlaylists: { uploads: "UU-official" } }
          } ]
        }.to_json
      when "/youtube/v3/playlistItems"
        {
          nextPageToken: "NEXT_PAGE",
          prevPageToken: "PREV_PAGE",
          items: [
            playlist_item("abc123DEF_4", "Una historia de esperanza", "public"),
            playlist_item("ZZZyyy111-2", "Vídeo privado", "private")
          ]
        }.to_json
      when "/youtube/v3/playlists"
        {
          items: [
            playlist_payload("PL-not-featured-01", "Mensajes de paz", 8),
            playlist_payload("PL75AE9E0550DBAD93", "Videos Especiales", 14),
            playlist_payload("PLFDD05D13D74978D0", "Levantaos y brillad", 18),
            playlist_payload("PL27339DE7B0837012", "Videos de la Bíblia", 104),
            playlist_payload("PLD68DBD93671935E7", "Historias del Libro de Mormón", 54)
          ]
        }.to_json
      when "/youtube/v3/search"
        {
          nextPageToken: "SEARCH_NEXT",
          items: [ {
            id: { videoId: "abc123DEF_4" },
            snippet: {
              title: "Una historia de esperanza",
              description: "Descripción",
              publishedAt: "2026-08-20T12:30:00Z"
            }
          } ]
        }.to_json
      when "/youtube/v3/videos"
        {
          items: [
            video_detail("abc123DEF_4", duration: "PT1H2M3S", privacy: "public", embeddable: true, made_for_kids: true),
            video_detail("ZZZyyy111-2", duration: "PT2M", privacy: "private", embeddable: false)
          ]
        }.to_json
      else
        raise "Unexpected YouTube request: #{uri.path}"
      end
    end

    def playlist_item(id, title, privacy)
      {
        snippet: {
          title:,
          description: "Descripción",
          publishedAt: "2026-08-20T12:30:00Z",
          resourceId: { videoId: id }
        },
        contentDetails: { videoId: id },
        status: { privacyStatus: privacy }
      }
    end

    def playlist_payload(id, title, count)
      {
        id:,
        snippet: {
          title:,
          description: "Colección oficial",
          thumbnails: { high: { url: "https://i.ytimg.com/vi/thumb1234_A/hqdefault.jpg" } }
        },
        contentDetails: { itemCount: count },
        status: { privacyStatus: "public" }
      }
    end

    def video_detail(id, duration:, privacy:, embeddable:, made_for_kids: false)
      {
        id:,
        contentDetails: { duration: },
        status: { privacyStatus: privacy, embeddable:, madeForKids: made_for_kids }
      }
    end

    def query_for(path)
      uri = @requests.find { |request| request.path == path }
      CGI.parse(uri.query)
    end
end
