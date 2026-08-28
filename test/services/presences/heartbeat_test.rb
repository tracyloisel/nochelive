require "test_helper"

class Presences::HeartbeatTest < ActiveSupport::TestCase
  test "marks the player live and refreshes presence" do
    lucia = players(:lucia)
    lucia.update_column(:last_seen_at, nil)
    snapshot = Presences::Heartbeat.call(player: lucia)
    assert lucia.live?
    assert_operator snapshot.live, :>=, 1
    assert_nil lucia.reload.last_seen_at
  end
end
