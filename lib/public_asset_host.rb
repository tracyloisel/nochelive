class PublicAssetHost
  ASSET_PATH = %r{(?<![A-Za-z0-9._~-])/(?:assets|marks|media|sfx)/}
  REWRITABLE_CONTENT_TYPES = %w[
    application/json
    application/xhtml+xml
    text/html
    text/vnd.turbo-stream.html
  ].freeze

  class RewritingBody
    include Enumerable

    def initialize(body, host)
      @body = body
      @host = host
    end

    def each
      return enum_for(:each) unless block_given?

      @body.each do |part|
        yield part.to_s.gsub(ASSET_PATH) { |path| "#{@host}#{path}" }
      end
    end

    def close
      @body.close if @body.respond_to?(:close)
    end
  end

  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)
    host = Rails.configuration.x.asset_host
    return [ status, headers, body ] unless host.present? && rewritable?(headers)

    headers = headers.dup
    headers.delete("Content-Length")
    headers.delete("content-length")
    headers.delete("ETag")
    headers.delete("etag")

    [ status, headers, RewritingBody.new(body, host) ]
  end

  private

    def rewritable?(headers)
      content_type = headers["content-type"] || headers["Content-Type"]
      REWRITABLE_CONTENT_TYPES.any? { |type| content_type.to_s.start_with?(type) }
    end
end
