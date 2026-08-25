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

  test "live window follows last_seen_at" do
    lucia = players(:lucia)
    lucia.update_column(:last_seen_at, Time.current)
    assert lucia.live?
    lucia.update_column(:last_seen_at, 1.minute.ago)
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
