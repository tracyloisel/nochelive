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

  test "entering a locator rama creates it and opens the profile" do
    Wards::QueryLocator.forced_details = Wards::QueryLocator.attrs_from(
      JSON.parse(file_fixture("maps_ward_madrid.json").read).first
    )

    post enter_ward_path, params: { church_unit_id: "999001" }
    ward = Ward.find_by!(church_unit_id: "999001")
    assert_redirected_to ward_profile_path(ward.code)
  end
end
