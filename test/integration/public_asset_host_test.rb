require "test_helper"

class PublicAssetHostTest < ActiveSupport::TestCase
  setup do
    @previous_asset_host = Rails.configuration.x.asset_host
    Rails.configuration.x.asset_host = "https://nochelive-assets-prod.storage.googleapis.com"
  end

  teardown do
    Rails.configuration.x.asset_host = @previous_asset_host
  end

  test "rewrites public asset paths without duplicating absolute URLs" do
    body = <<~HTML
      <img src="/media/story.webp">
      <audio src='/sfx/tick.mp3'></audio>
      <img src="/marks/avatars/delfin.jpg">
      <script>{"asset":"/assets/application.js"}</script>
      <img src="https://nochelive-assets-prod.storage.googleapis.com/media/already-hosted.webp">
    HTML
    app = ->(_env) { [ 200, { "content-type" => "text/html; charset=utf-8", "content-length" => body.bytesize.to_s }, [ body ] ] }

    status, headers, response = PublicAssetHost.new(app).call({})
    rendered = response.to_a.join

    assert_equal 200, status
    assert_includes rendered, "https://nochelive-assets-prod.storage.googleapis.com/media/story.webp"
    assert_includes rendered, "https://nochelive-assets-prod.storage.googleapis.com/sfx/tick.mp3"
    assert_includes rendered, "https://nochelive-assets-prod.storage.googleapis.com/marks/avatars/delfin.jpg"
    assert_includes rendered, "https://nochelive-assets-prod.storage.googleapis.com/assets/application.js"
    assert_equal 1, rendered.scan("https://nochelive-assets-prod.storage.googleapis.com/media/already-hosted.webp").size
    refute headers.key?("content-length")
  end

  test "streams rewritten chunks without buffering the response" do
    consumed = false
    body = Object.new
    body.define_singleton_method(:each) do |&block|
      consumed = true
      block.call('<main><img src="/media/story.webp">')
      block.call('<audio src="/sfx/tick.mp3"></audio></main>')
    end
    app = ->(_env) { [ 200, { "content-type" => "text/html" }, body ] }

    _status, _headers, response = PublicAssetHost.new(app).call({})

    assert_not consumed, "middleware must not consume the full HTML body before Rack starts sending it"
    rendered = response.each.to_a.join
    assert consumed
    assert_includes rendered, "https://nochelive-assets-prod.storage.googleapis.com/media/story.webp"
    assert_includes rendered, "https://nochelive-assets-prod.storage.googleapis.com/sfx/tick.mp3"
  end

  test "leaves non-document responses untouched" do
    body = "/media/story.webp"
    app = ->(_env) { [ 200, { "content-type" => "image/webp" }, [ body ] ] }

    _status, _headers, response = PublicAssetHost.new(app).call({})

    assert_equal body, response.join
  end
end
