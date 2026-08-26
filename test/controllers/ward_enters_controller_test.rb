require "test_helper"

class WardEntersControllerTest < ActionDispatch::IntegrationTest
  test "choosing a rama remembers it and opens the profile" do
    post enter_ward_path, params: { code: "RAMA" }
    assert_redirected_to ward_profile_path("RAMA")
    get root_path
    assert_response :success
    assert_select "#street_world"
  end

  test "rejects a missing rama" do
    post enter_ward_path, params: { code: "NOPE" }
    assert_redirected_to search_path
  end
end
