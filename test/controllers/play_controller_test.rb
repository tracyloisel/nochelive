require "test_helper"

class PlayAndWatchControllerTest < ActionDispatch::IntegrationTest
  setup { @night = game_sessions(:david) }

  test "play requires a player" do
    get night_play_path(@night.code)
    assert_redirected_to night_name_path(@night.code)
  end

  test "play shows the night for a teammate" do
    sign_in_as_participant(@night, name: "Sofía", team: teams(:leones))
    get night_play_path(@night.code)
    assert_response :success
  end

  test "watch creates a spectator" do
    assert_difference -> { @night.players.where(role: "spectator").count }, 1 do
      get night_watch_path(@night.code)
    end
    assert_response :success
  end
end
