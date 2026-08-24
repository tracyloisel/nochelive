require "test_helper"

class TeamsAndMembershipsControllerTest < ActionDispatch::IntegrationTest
  setup { @night = game_sessions(:david) }

  test "create a team and join it" do
    sign_in_as_participant(@night, name: "Sofía")
    assert_difference -> { @night.teams.count }, 1 do
      post night_teams_path(@night.code), params: { name: "Profetas", emblem: "fuego" }
    end
    assert_redirected_to night_play_path(@night.code)
    assert_equal "Profetas", Player.order(:id).last.team.name
  end

  test "duplicate team name" do
    sign_in_as_participant(@night, name: "Sofía")
    post night_teams_path(@night.code), params: { name: "Leones de Judá", emblem: "leon" }
    assert_redirected_to night_play_path(@night.code)
  end

  test "join an existing team" do
    sign_in_as_participant(@night, name: "Sofía")
    post night_team_memberships_path(@night.code, teams(:leones))
    assert_redirected_to night_play_path(@night.code)
    assert_equal teams(:leones), Player.order(:id).last.team
  end

  test "switching teams" do
    sign_in_as_participant(@night, name: "Sofía", team: teams(:leones))
    post night_team_memberships_path(@night.code, teams(:casa))
    assert_equal teams(:casa), Player.order(:id).last.team
  end
end
