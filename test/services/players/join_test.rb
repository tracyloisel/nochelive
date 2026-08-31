require "test_helper"

class Players::JoinTest < ActiveSupport::TestCase
  test "registration creates no team and emits a semantic event" do
    night = game_sessions(:elias)
    player = Players::Join.call(night:, name: "Lina", device_token: "lina", locale: "fr")

    assert_nil player.team
    assert_equal "fr", player.locale
    assert night.live_events.exists?(kind: "join", dedupe_key: "join:#{player.id}")
  end
end
