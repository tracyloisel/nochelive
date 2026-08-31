require "test_helper"

class TeamTest < ActiveSupport::TestCase
  test "a Noche team is always a snapshot of a persistent ward team" do
    team = teams(:leones)

    assert team.ward_team
    assert_equal game_sessions(:david), team.game_session
  end
end
