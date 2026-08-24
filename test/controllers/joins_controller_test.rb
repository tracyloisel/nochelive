require "test_helper"

class JoinsControllerTest < ActionDispatch::IntegrationTest
  test "join by code case-insensitively" do
    post join_path, params: { code: "david" }
    assert_redirected_to night_name_path("DAVID")
  end

  test "watch join" do
    post join_path, params: { code: "DAVID", as: "watch" }
    assert_redirected_to night_watch_path("DAVID")
  end

  test "present join goes to the presenter gate" do
    post join_path, params: { code: "david", as: "present" }
    assert_redirected_to presenter_gate_path("DAVID")
  end

  test "unknown code" do
    post join_path, params: { code: "XXXXX" }
    assert_redirected_to root_path
  end
end
