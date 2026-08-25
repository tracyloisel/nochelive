require "test_helper"

class StreetProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_congregation
  end

  test "show prompts for a profile when none is signed in" do
    get street_profile_path
    assert_response :success
    assert_select "h1", text: I18n.t("street.create_title")
  end

  test "create remembers a person on the device" do
    post street_profile_path, params: {
      name: "Nuevo",
      avatar_key: "delfin",
      favorite_year: 2010
    }
    assert_redirected_to root_path
    follow_redirect!
    assert_select ".street-person .word", text: "Nuevo"
  end

  test "guest clears the street profile" do
    post street_profile_path, params: {
      name: "Nuevo",
      avatar_key: "delfin",
      favorite_year: 2010
    }
    follow_redirect!
    assert_select ".street-person .word", text: "Nuevo"

    post street_profile_path, params: { guest: 1 }
    assert_redirected_to root_path
    follow_redirect!
    assert_select ".street-person.is-guest"
  end
end
