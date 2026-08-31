require "test_helper"

class StreetWardPicksControllerTest < ActionDispatch::IntegrationTest
  test "guest pick only remembers the rama" do
    dest = extra_ward(7, listed: true)
    post street_ward_pick_path, params: { code: dest.code }
    assert_redirected_to root_path
    assert_equal I18n.t("flashes.street_ward_selected_guest", ward: dest.name), flash[:notice]
    follow_redirect!
    assert_select "a.home-menu-row[href=?]", search_path(cambiar: 1), count: 1
    assert_select ".banner", text: I18n.t("flashes.street_ward_selected_guest", ward: dest.name)
  end

  test "signed-in player keeps points on the new rama board" do
    dest = extra_ward(8, listed: true)
    sign_in_congregation
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    follow_redirect!

    post street_ward_pick_path, params: { code: dest.code }
    assert_redirected_to root_path
    assert_equal I18n.t("flashes.street_ward_changed", ward: dest.name), flash[:notice]
    follow_redirect!
    assert_equal dest.id, pili.reload.ward_id
    assert_select ".quiz-hud-name", text: "Pili"
    assert_select "a.home-menu-row[href=?]", search_path(cambiar: 1), count: 1

    get street_leaderboard_path
    assert_response :success
    assert_select ".liga-court-podium-place.is-you", text: /Pili/
    assert_select ".liga-court-podium-place.is-you", text: /95/
    assert_select ".liga-court-podium-place", text: /Carmen/, count: 0
  end

  test "rejects a missing rama" do
    post street_ward_pick_path, params: { code: "NOPE" }
    assert_redirected_to search_path(cambiar: 1)
  end

  test "profile ward change returns to the profile" do
    dest = extra_ward(18, listed: true)
    sign_in_congregation
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }

    get player_profile_path(pili, ward_next: 1)
    assert_redirected_to search_path(cambiar: 1)

    post street_ward_pick_path, params: { code: dest.code }
    assert_redirected_to player_profile_path(pili)
    assert_equal dest.id, pili.reload.ward_id
  end

  test "picking a locator rama creates it listed" do
    Wards::QueryLocator.forced_details = Wards::QueryLocator.attrs_from(
      JSON.parse(file_fixture("maps_ward_madrid.json").read).first
    )

    post street_ward_pick_path, params: { church_unit_id: "999001" }
    ward = Ward.find_by!(church_unit_id: "999001")
    assert_redirected_to root_path
    follow_redirect!
    assert ward.listed?
    assert_equal 0, ward.people.count
    assert_select "a.home-menu-row[href=?]", search_path(cambiar: 1), count: 1
    assert_select ".banner", text: I18n.t("flashes.street_ward_selected_guest", ward: ward.name)
  end
end
