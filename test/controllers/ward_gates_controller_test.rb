require "test_helper"

class WardGatesControllerTest < ActionDispatch::IntegrationTest
  test "opens a rama with the secret" do
    get ward_gate_path
    assert_response :success
    post ward_gate_path, params: { code: "RAMA", token: "rama-demo" }
    assert_redirected_to new_game_session_path
  end

  test "rejects a bad secret" do
    post ward_gate_path, params: { code: "RAMA", token: "nope" }
    assert_response :unprocessable_entity
  end
end
