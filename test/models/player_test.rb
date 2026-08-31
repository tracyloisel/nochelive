require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  test "a Noche player has no role and starts without an automatic team" do
    player = game_sessions(:elias).players.create!(name: "Noa", client_token: "noa", avatar_key: "delfin")

    assert_equal game_sessions(:elias), player.game_session
    assert_nil player.team
  end
end
