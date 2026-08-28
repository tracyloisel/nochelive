require "test_helper"

class PresenceChannelTest < ActionCable::Channel::TestCase
  test "night subscription registers and removes the verified player" do
    player = players(:lucia)

    subscribe(scope: "night", token: player.signed_id(purpose: :night_presence))

    assert subscription.confirmed?
    assert Presences::Registry.player_online?(player.id, night_id: player.game_session_id)

    unsubscribe

    assert_not Presences::Registry.player_online?(player.id, night_id: player.game_session_id)
  end

  test "street subscription rejects an anonymous connection" do
    subscribe(scope: "street", token: "invalid")

    assert subscription.rejected?
    assert_equal 0, Presences::Registry.live_count
  end

  test "heartbeat revives an expired subscription through the socket" do
    player = players(:lucia)
    subscribe(scope: "night", token: player.signed_id(purpose: :night_presence))

    travel Presences::Registry::ACTIVE_WINDOW + 1.second do
      assert_not Presences::Registry.player_online?(player.id, night_id: player.game_session_id)
      perform :heartbeat
      assert Presences::Registry.player_online?(player.id, night_id: player.game_session_id)
    end
  end
end
