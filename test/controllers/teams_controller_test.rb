require "test_helper"

class TeamsControllerTest < ActionDispatch::IntegrationTest
  test "team selection route stays scoped to the Noche" do
    night = game_sessions(:elias)
    assert_routing(
      { method: :post, path: night_team_memberships_path(night.code, teams(:lobby_leones)) },
      { controller: "memberships", action: "create", session_code: night.code, team_id: teams(:lobby_leones).id.to_s }
    )
  end
end
