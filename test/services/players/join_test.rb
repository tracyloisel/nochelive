require "test_helper"

class Players::JoinTest < ActiveSupport::TestCase
  setup { @night = game_sessions(:elias) }

  test "guest join has no person" do
    player = Players::Join.call(
      night: @night,
      name: "Marta",
      role: "participant",
      location: "room",
      device_token: "guest-phone",
      avatar_key: "perro"
    )
    assert_nil player.person_id
    assert_equal "perro", player.avatar_key
  end

  test "joining with a person reuses the night player" do
    person = people(:pili)
    first = Players::Join.call(
      night: @night,
      name: person.given_name,
      role: "participant",
      location: "room",
      device_token: "pili-tablet",
      person: person
    )
    second = Players::Join.call(
      night: @night,
      name: person.given_name,
      role: "participant",
      location: "room",
      device_token: "pili-tablet",
      person: person
    )
    assert_equal first.id, second.id
  end

  test "remote join seats a solo team" do
    player = Players::Join.call(
      night: @night,
      name: "Daniel",
      role: "participant",
      location: "remote",
      device_token: "casa-phone"
    )
    assert player.remote?
    assert player.team.solo?
    assert_equal "Daniel", player.team.name
  end

  test "remote spectator is not seated" do
    player = Players::Join.call(
      night: @night,
      name: "TV",
      role: "spectator",
      location: "remote",
      device_token: "tv-box"
    )
    assert_nil player.team
  end
end
