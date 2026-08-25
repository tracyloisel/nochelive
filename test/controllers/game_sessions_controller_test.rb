require "test_helper"

class GameSessionsControllerTest < ActionDispatch::IntegrationTest
  test "new and create a night" do
    get new_game_session_path
    assert_redirected_to root_path

    post game_sessions_path
    assert_redirected_to ward_gate_path

    post wards_path, params: { name: "Rama Valencia" }
    follow_redirect!

    assert_difference -> { GameSession.count }, 1 do
      post game_sessions_path
    end
    follow_redirect!
    assert_response :success
  end

  test "open rama can enter the live night from the profile" do
    sign_in_ward
    get ward_profile_path("RAMA")
    assert_response :success
    assert_select ".btn.btn-gold", text: /Entrar/

    post presenter_claim_path("DAVID")
    assert_redirected_to presenter_console_path("DAVID")
  end

  test "created page requires the presenter token" do
    night = game_sessions(:david)
    get created_game_session_path(night, token: "presenter-secret")
    assert_redirected_to root_path

    post game_sessions_path
    assert_redirected_to ward_gate_path

    post wards_path, params: { name: "Rama Valencia" }
    follow_redirect!
    post game_sessions_path
    follow_redirect!
    assert_response :success

    night = GameSession.order(:id).last
    get created_game_session_path(night, token: "nope")
    assert_redirected_to root_path
  end
end
