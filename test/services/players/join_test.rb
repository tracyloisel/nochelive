require "test_helper"

class Players::JoinTest < ActiveSupport::TestCase
  setup { @night = game_sessions(:elias) }

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
    person = people(:pili)
    player = Players::Join.call(
      night: @night,
      name: person.given_name,
      role: "participant",
      location: "remote",
      device_token: "casa-phone",
      person:
    )
    assert player.remote?
    assert player.team.solo?
    assert_equal person.given_name, player.team.name
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

  test "participant join pulses chest" do
    pulses = []
    original = GameSession.instance_method(:broadcast_state)
    GameSession.define_method(:broadcast_state) { |pulse: nil| pulses << pulse }
    person = people(:pili)
    player = Players::Join.call(
      night: @night,
      name: person.given_name,
      role: "participant",
      location: "room",
      device_token: "profile-phone-2",
      person:
    )
    GameSession.define_method(:broadcast_state, original)

    assert_equal "join", pulses.last[:kind]
    assert_equal player.id, pulses.last[:player].id
    assert_equal "chest", Sfx.for_pulse("join")
  ensure
    GameSession.define_method(:broadcast_state, original) if original
  end
end
