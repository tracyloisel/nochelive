require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  test "fixture player is a room participant" do
    lucia = players(:lucia)
    assert_includes Player::AVATARS, players(:lucia).avatar_key
    assert lucia.participant?
    assert_not lucia.spectator?
    assert_not lucia.remote?
    assert_equal teams(:leones), lucia.team
  end

  test "remote spectator predicates" do
    publico = players(:publico)
    assert publico.spectator?
    daniel = players(:daniel)
    assert daniel.remote?
    assert_equal teams(:daniel_home), daniel.team
  end

  test "live state follows the realtime registry, not last_seen_at" do
    lucia = players(:lucia)
    entry = mark_player_online(lucia)
    assert lucia.live?
    Presences::Registry.leave(entry)
    assert_not lucia.live?
  end

  test "rejects a blank name" do
    player = game_sessions(:david).players.new(
      name: "",
      role: "participant",
      location: "room",
      client_token: SecureRandom.uuid
    )
    assert_not player.valid?
  end
end
