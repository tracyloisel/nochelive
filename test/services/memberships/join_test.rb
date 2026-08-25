require "test_helper"

class Memberships::JoinTest < ActiveSupport::TestCase
  test "remembers the season team on the ficha" do
    night = game_sessions(:elias)
    person = people(:pili)
    player = Players::Join.call(
      night:,
      name: person.given_name,
      role: "participant",
      location: "room",
      device_token: "pili-tablet",
      person:
    )
    team = Teams::Create.call(night:, name: "Leones de Judá", emblem: "leon")
    Memberships::Join.call(night:, player:, team:)
    assert_equal team, player.reload.team
    assert_equal team.ward_team, person.reload.last_ward_team
  end

  test "rejects a remote player" do
    error = assert_raises(People::Error) do
      Memberships::Join.call(night: game_sessions(:david), player: players(:daniel), team: teams(:leones))
    end
    assert_equal :location, error.code
  end

  test "rejects joining a casa seat" do
    error = assert_raises(People::Error) do
      Memberships::Join.call(night: game_sessions(:david), player: players(:ana), team: teams(:daniel_home))
    end
    assert_equal :team, error.code
  end
end
