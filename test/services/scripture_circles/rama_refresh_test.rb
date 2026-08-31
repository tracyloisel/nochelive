require "test_helper"

class ScriptureCircles::RamaRefreshTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  setup do
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
  end

  test "broadcasts a content-free Turbo refresh only to the readable rama" do
    messages = capture_broadcasts(stream_name(@ward)) do
      ScriptureCircles::RamaRefresh.call(ward: @ward)
    end

    assert_equal [ "<turbo-stream action=\"circle_refresh\" target=\"circle_live_feed\"><template></template></turbo-stream>" ], messages
  end

  test "identifies the post that already arrives in the publisher frame" do
    messages = capture_broadcasts(stream_name(@ward)) do
      ScriptureCircles::RamaRefresh.call(ward: @ward, post_id: 42)
    end

    stream = Nokogiri::HTML5.fragment(messages.fetch(0)).at_css("turbo-stream")
    assert_equal "circle_refresh", stream["action"]
    assert_equal "circle_live_feed", stream["target"]
    assert_equal "42", stream["post-id"]
    assert_empty stream.at_css("template").text
  end

  test "does not broadcast when the Circle is disabled" do
    @ward.update!(scripture_circle_mode: "disabled")

    assert_no_broadcasts stream_name(@ward) do
      ScriptureCircles::RamaRefresh.call(ward: @ward)
    end
  end

  test "does not signal a different rama" do
    other_ward = extra_ward(86, scripture_circle_mode: "active")

    assert_no_broadcasts stream_name(other_ward) do
      ScriptureCircles::RamaRefresh.call(ward: @ward)
    end
  end

  private

    def stream_name(ward)
      [ ward.to_gid_param, ScriptureCircles::RamaRefresh::STREAM ].join(":")
    end
end
