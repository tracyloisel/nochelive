require "json"
require "net/http"
require "uri"
require "yaml"
require "digest"

module ChurchVideos
  class Catalog
    API = "https://www.googleapis.com/youtube/v3"
    CONFIG_PATH = Rails.root.join("config/media/church_youtube.yml")
    PER_PAGE = 24
    CHANNEL_TTL = 12.hours
    PAGE_TTL = 30.minutes
    MISS_TTL = 30.seconds
    OPEN_TIMEOUT = 4
    READ_TIMEOUT = 8
    USER_AGENT = "NocheLive/1.0 (official church video catalog)"
    PAGE_TOKEN = /\A[A-Za-z0-9_-]{1,256}\z/
    PLAYLIST_ID = /\A[A-Za-z0-9_-]{10,128}\z/
    VIDEO_ID = /\A[A-Za-z0-9_-]{11}\z/
    MAX_QUERY_LENGTH = 100
    MAX_PLAYLIST_PAGES = 5
    CACHE_VERSION = "v3"

    Error = Class.new(StandardError)
    Channel = Struct.new(:id, :title, :description, :uploads_playlist_id, :public_url, keyword_init: true)
    Playlist = Struct.new(:id, :title, :description, :video_count, :thumbnail_video_id, :featured, keyword_init: true)
    Video = Struct.new(:id, :title, :description, :published_at, :duration_seconds, :made_for_kids, keyword_init: true)
    Result = Struct.new(
      :channel,
      :playlists,
      :active_playlist,
      :query,
      :videos,
      :next_page_token,
      :previous_page_token,
      :error,
      keyword_init: true
    ) do
      def available?
        error.nil?
      end
    end

    class << self
      attr_accessor :transport, :forced_result

      def call(locale: I18n.locale, page_token: nil, playlist_id: nil, query: nil, cache: Rails.cache, api_key: ENV["YOUTUBE_API_KEY"])
        return forced_result if forced_result

        new(locale:, page_token:, playlist_id:, query:, cache:, api_key:).call
      end

      def configuration
        @configuration ||= YAML.safe_load_file(CONFIG_PATH, aliases: false)
      end

      def artwork
        configuration.fetch("artwork")
      end

      def official_channel_id(locale)
        configuration.fetch("channels").fetch(Locale.cast(locale)).fetch("id")
      end

      def official_channel_id?(locale:, channel_id:)
        ActiveSupport::SecurityUtils.secure_compare(official_channel_id(locale), channel_id.to_s)
      rescue KeyError, ArgumentError
        false
      end

      def scripture_candidates(reference:, locale: I18n.locale, themes: [], **options)
        ScriptureCandidates.call(reference:, locale:, themes:, **options)
      end

      def http_get(uri)
        (transport || method(:net_http_get)).call(uri)
      end

      def net_http_get(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = OPEN_TIMEOUT
        http.read_timeout = READ_TIMEOUT
        request = Net::HTTP::Get.new(uri)
        request["Accept"] = "application/json"
        request["User-Agent"] = USER_AGENT
        response = http.request(request)
        response.body if response.is_a?(Net::HTTPSuccess)
      end
    end

    def initialize(locale:, page_token:, playlist_id:, query:, cache:, api_key:)
      @locale = Locale.cast(locale)
      @page_token = valid_page_token(page_token)
      @playlist_id = valid_playlist_id(playlist_id)
      @query = clean_query(query)
      @cache = cache
      @api_key = api_key.to_s.strip
    end

    def call
      return failure(:not_configured) if @api_key.blank?

      cached = @cache.read(page_key)
      return cached if cached
      return failure(:unavailable) if @cache.read(miss_key)

      result = fetch_catalog
      @cache.write(page_key, result, expires_in: PAGE_TTL)
      result
    rescue StandardError
      @cache.write(miss_key, true, expires_in: MISS_TTL)
      failure(:unavailable)
    end

    private

      def fetch_catalog
        channel = fetch_channel
        playlists = fetch_playlists(channel)
        active_playlist = selected_playlist(playlists)
        page = @query.present? ? fetch_search_page(channel) : fetch_playlist_page(channel, active_playlist)
        items = Array(page["items"])
        details = fetch_video_details(items)

        videos = items.filter_map do |item|
          id = video_id_for(item)
          detail = details[id]
          next if id.blank? || detail.blank?
          next if item.dig("status", "privacyStatus").present? && item.dig("status", "privacyStatus") != "public"
          next unless detail.dig("status", "privacyStatus") == "public"
          next unless detail.dig("status", "embeddable")

          snippet = item.fetch("snippet", {})
          Video.new(
            id:,
            title: snippet["title"].to_s,
            description: snippet["description"].to_s,
            published_at: parse_time(snippet["publishedAt"]),
            duration_seconds: parse_duration(detail.dig("contentDetails", "duration")),
            made_for_kids: detail.dig("status", "madeForKids") == true
          )
        end

        Result.new(
          channel:,
          playlists:,
          active_playlist:,
          query: @query,
          videos:,
          next_page_token: page["nextPageToken"],
          previous_page_token: page["prevPageToken"],
          error: nil
        )
      end

      def fetch_playlist_page(channel, active_playlist)
        api_get(
          "playlistItems",
          part: "snippet,contentDetails,status",
          playlistId: active_playlist&.id || channel.uploads_playlist_id,
          maxResults: PER_PAGE,
          pageToken: @page_token,
          hl: language_code
        )
      end

      def fetch_search_page(channel)
        api_get(
          "search",
          part: "snippet",
          channelId: channel.id,
          q: @query,
          type: "video",
          videoEmbeddable: "true",
          videoSyndicated: "true",
          maxResults: PER_PAGE,
          pageToken: @page_token,
          relevanceLanguage: search_language_code
        )
      end

      def fetch_channel
        cached = @cache.read(channel_key)
        return cached if cached

        config = channel_config
        lookup = config["id"].present? ? { id: config["id"] } : { forHandle: config.fetch("for_handle") }
        payload = api_get("channels", **lookup, part: "snippet,contentDetails", hl: language_code)
        item = Array(payload["items"]).first
        raise Error, "Official YouTube channel not found" unless item

        channel = Channel.new(
          id: item["id"],
          title: item.dig("snippet", "title").to_s,
          description: item.dig("snippet", "description").to_s,
          uploads_playlist_id: item.dig("contentDetails", "relatedPlaylists", "uploads"),
          public_url: config.fetch("public_url")
        )
        raise Error, "Official YouTube uploads playlist missing" if channel.uploads_playlist_id.blank?

        @cache.write(channel_key, channel, expires_in: CHANNEL_TTL)
        channel
      end

      def fetch_playlists(channel)
        cached = @cache.read(playlists_key)
        return cached if cached

        playlists = []
        page_token = nil

        MAX_PLAYLIST_PAGES.times do
          payload = api_get(
            "playlists",
            part: "snippet,contentDetails,status",
            channelId: channel.id,
            maxResults: 50,
            pageToken: page_token,
            hl: language_code
          )
          playlists.concat(Array(payload["items"]).filter_map { |item| build_playlist(item) })
          page_token = payload["nextPageToken"]
          break if page_token.blank?
        end

        featured_ids = featured_playlist_ids
        playlists = playlists.each_with_index.sort_by do |playlist, index|
          featured_rank = featured_ids.index(playlist.id)
          featured_rank ? [ 0, featured_rank ] : [ 1, index ]
        end.map(&:first)
        @cache.write(playlists_key, playlists, expires_in: CHANNEL_TTL)
        playlists
      end

      def build_playlist(item)
        return unless item.dig("status", "privacyStatus") == "public"

        id = item["id"].to_s
        return unless id.match?(PLAYLIST_ID)

        Playlist.new(
          id:,
          title: item.dig("snippet", "title").to_s,
          description: item.dig("snippet", "description").to_s,
          video_count: item.dig("contentDetails", "itemCount").to_i,
          thumbnail_video_id: thumbnail_video_id(item.dig("snippet", "thumbnails")),
          featured: featured_playlist_ids.include?(id)
        )
      end

      def featured_playlist_ids
        Array(config.fetch("featured_playlists", {})[@locale])
      end

      def thumbnail_video_id(thumbnails)
        url = %w[maxres high medium default].filter_map { |key| thumbnails&.dig(key, "url") }.first
        match = url.to_s.match(%r{/vi/([A-Za-z0-9_-]{11})/})
        match[1] if match && match[1].match?(VIDEO_ID)
      end

      def selected_playlist(playlists)
        return if @query.present? || @playlist_id.blank?

        playlists.find { |playlist| playlist.id == @playlist_id }
      end

      def fetch_video_details(items)
        ids = items.filter_map { |item| video_id_for(item) }.uniq
        return {} if ids.empty?

        payload = api_get("videos", id: ids.join(","), part: "contentDetails,status")
        Array(payload["items"]).index_by { |item| item["id"] }
      end

      def video_id_for(item)
        item.dig("contentDetails", "videoId") ||
          item.dig("snippet", "resourceId", "videoId") ||
          item.dig("id", "videoId")
      end

      def api_get(resource, params)
        clean = params.compact_blank.merge(key: @api_key)
        uri = URI.parse("#{API}/#{resource}?#{URI.encode_www_form(clean)}")
        body = self.class.http_get(uri)
        raise Error, "YouTube API unavailable" if body.blank?

        payload = JSON.parse(body)
        raise Error, "YouTube API error" if payload["error"].present?

        payload
      rescue JSON::ParserError
        raise Error, "Invalid YouTube API response"
      end

      def config
        self.class.configuration
      end

      def channel_config
        config.fetch("channels").fetch(@locale)
      end

      def language_code
        { "pt-BR" => "pt-BR" }.fetch(@locale, @locale)
      end

      def search_language_code
        { "pt-BR" => "pt" }.fetch(@locale, @locale)
      end

      def valid_page_token(value)
        value.to_s.match?(PAGE_TOKEN) ? value.to_s : nil
      end

      def valid_playlist_id(value)
        value.to_s.match?(PLAYLIST_ID) ? value.to_s : nil
      end

      def clean_query(value)
        value.to_s.scrub.strip.gsub(/\s+/, " ").first(MAX_QUERY_LENGTH).to_s
      end

      def parse_time(value)
        Time.iso8601(value.to_s)
      rescue ArgumentError
        nil
      end

      def parse_duration(value)
        match = value.to_s.match(/\APT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?\z/)
        return 0 unless match

        match[1].to_i * 3600 + match[2].to_i * 60 + match[3].to_i
      end

      def failure(reason)
        Result.new(
          channel: nil,
          playlists: [],
          active_playlist: nil,
          query: @query,
          videos: [],
          next_page_token: nil,
          previous_page_token: nil,
          error: reason
        )
      end

      def channel_key
        [ "church-youtube-channel", CACHE_VERSION, @locale ]
      end

      def playlists_key
        [ "church-youtube-playlists", CACHE_VERSION, @locale ]
      end

      def page_key
        [ "church-youtube-page", CACHE_VERSION, @locale, @playlist_id || "uploads", query_digest, @page_token || "first" ]
      end

      def miss_key
        [ "church-youtube-miss", CACHE_VERSION, @locale, @playlist_id || "uploads", query_digest, @page_token || "first" ]
      end

      def query_digest
        @query.present? ? Digest::SHA256.hexdigest(@query) : "browse"
      end
  end
end
