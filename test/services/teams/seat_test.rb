require "test_helper"

class Teams::SeatTest < ActiveSupport::TestCase
  setup { @night = game_sessions(:elias) }

  test "creates a solo seat named after the player" do
    player = Players::Join.call(
      night: @night,
      name: "Daniel",
      role: "participant",
      location: "remote",
      device_token: "casa-phone",
      avatar_key: "elefante"
    )
    team = player.reload.team
    assert team.solo?
    assert_equal "Daniel", team.name
    assert_equal team, Teams::Seat.call(night: @night, player: player)
  end

  test "disambiguates a taken name" do
    add_team(@night, name: "Marta")
    player = Players::Join.call(
      night: @night,
      name: "Marta",
      role: "participant",
      location: "remote",
      device_token: "casa-two"
    )
    assert_equal "Marta · 2", player.reload.team.name
    assert player.team.solo?
  end

  test "rejects a room player" do
    player = players(:lucia)
    assert_raises(People::Error) { Teams::Seat.call(night: game_sessions(:david), player: player) }
  end
end
