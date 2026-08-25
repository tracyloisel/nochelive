require "test_helper"

class Teams::CreateTest < ActiveSupport::TestCase
  setup { @night = game_sessions(:david) }

  test "creates a team and joins the player" do
    player = players(:ana)
    team = Teams::Create.call(night: @night, player: player, name: " Profetas ", emblem: "fuego")
    assert_equal "Profetas", team.name
    assert_equal "fuego", team.emblem
    assert_equal team, player.reload.team
  end

  test "picks a known emblem when the mark is unknown" do
    player = players(:ana)
    team = Teams::Create.call(night: @night, player: player, name: "Nómadas", emblem: "dragon")
    assert Team::EMBLEMS.key?(team.emblem)
    assert_equal team, player.reload.team
  end

  test "rejects a remote player" do
    error = assert_raises(People::Error) do
      Teams::Create.call(night: @night, player: players(:daniel), name: "Profetas", emblem: "fuego")
    end
    assert_equal :location, error.code
    assert_not @night.teams.exists?(name: "Profetas")
  end
end
