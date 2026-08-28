require "net/http"
require "uri"

module ChurchVideos
  class Thumbnail
    HOST = "i.ytimg.com"
    VIDEO_ID = /\A[A-Za-z0-9_-]{11}\z/
    HIT_TTL = 30.minutes
    MISS_TTL = 30.seconds
    OPEN_TIMEOUT = 4
    READ_TIMEOUT = 8
    USER_AGENT = "NocheLive/1.0 (video thumbnail proxy)"

    Image = Struct.new(:body, :content_type, keyword_init: true)

    class << self
      attr_accessor :fetcher, :forced_response

      def call(video_id:, cache: Rails.cache)
        return nil if forced_response == false
        return forced_response if forced_response

        new(video_id:, cache:).call
      end

      def http_get(uri)
        (fetcher || method(:net_http_get)).call(uri)
      end

      def net_http_get(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = OPEN_TIMEOUT
        http.read_timeout = READ_TIMEOUT
        request = Net::HTTP::Get.new(uri)
        request["Accept"] = "image/avif,image/webp,image/jpeg"
        request["User-Agent"] = USER_AGENT
        response = http.request(request)
        return unless response.is_a?(Net::HTTPSuccess)

        Image.new(body: response.body, content_type: response["Content-Type"].presence || "image/jpeg")
      end
    end

    def initialize(video_id:, cache:)
      @video_id = video_id.to_s
      @cache = cache
    end

    def call
      return unless @video_id.match?(VIDEO_ID)

      cached = @cache.read(hit_key)
      return cached if cached
      return if @cache.read(miss_key)

      image = self.class.http_get(uri)
      if image&.body.present?
        @cache.write(hit_key, image, expires_in: HIT_TTL)
      else
        @cache.write(miss_key, true, expires_in: MISS_TTL)
      end
      image
    rescue StandardError
      @cache.write(miss_key, true, expires_in: MISS_TTL)
      nil
    end

    private

      def uri
        URI::HTTPS.build(host: HOST, path: "/vi/#{@video_id}/mqdefault.jpg")
      end

      def hit_key
        [ "church-video-thumbnail", @video_id ]
      end

      def miss_key
        [ "church-video-thumbnail-miss", @video_id ]
      end
  end
end
