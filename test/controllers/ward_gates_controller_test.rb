require "test_helper"

class WardGatesControllerTest < ActionDispatch::IntegrationTest
  test "opens a rama with the secret" do
    get ward_gate_path
    assert_response :success
    assert_select "body.is-paper-hall"
    assert_select "#ward_gate.hall-paper"
    assert_select ".hall-sheet"
    assert_select "a[href=?]", add_ward_path
    assert_select "a[href=?]", new_ward_path, count: 0
    assert_select ".btn.btn-gold", count: 1
    assert_select ".play-reel", count: 0
    assert_select ".gate", count: 0
    assert_select "p.skip", count: 0
    post ward_gate_path, params: { code: "RAMA", token: "rama-demo" }
    assert_redirected_to ward_profile_path("RAMA")
  end

  test "rejects a bad secret" do
    post ward_gate_path, params: { code: "RAMA", token: "nope" }
    assert_response :unprocessable_entity
  end
end
