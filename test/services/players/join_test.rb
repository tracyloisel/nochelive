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
end
