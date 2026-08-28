require "test_helper"

class Presences::SnapshotTest < ActiveSupport::TestCase
  test "counts live room and remote participants" do
    lucia = players(:lucia)
    daniel = players(:daniel)
    mark_player_online(lucia)
    mark_player_online(daniel)

    snapshot = Presences::Snapshot.call(night: game_sessions(:david))
    assert_equal 3, snapshot.joined
    assert_equal 2, snapshot.live
    assert_equal 1, snapshot.room
    assert_equal 1, snapshot.remote
    leones = snapshot.teams.find { |row| row.team == teams(:leones) }
    assert_equal 1, leones.live
  end
end
