require "test_helper"

class PlayersControllerTest < ActionDispatch::IntegrationTest
  setup { @night = game_sessions(:elias) }

  test "a player can register before the lobby without choosing a team" do
    post night_players_path(@night.code), params: { name: "Sofía" }

    player = @night.players.order(:id).last
    assert_redirected_to night_path(@night.code)
    assert_equal "Sofía", player.name
    assert_nil player.team
  end

  test "late registration remains open during the live hour" do
    @night.update_columns(starts_at: 5.minutes.ago, ends_at: 55.minutes.from_now, status: "playing")
    post night_players_path(@night.code), params: { name: "Carlos" }

    assert_redirected_to night_path(@night.code)
    assert @night.players.exists?(name: "Carlos")
  end

  test "registration closes after the automatic end" do
    @night.update_columns(starts_at: 2.hours.ago, ends_at: 1.hour.ago, status: "finished", closed_at: 1.hour.ago)
    post night_players_path(@night.code), params: { name: "Tarde" }

    assert_response :unprocessable_entity
    assert_not @night.players.exists?(name: "Tarde")
  end
end
