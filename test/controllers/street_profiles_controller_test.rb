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

  test "guest clears the street profile and closes the gate" do
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
    assert_select "#profile_gate", count: 0
    assert_select "#street_quiz"
  end

  test "create claims an existing unique name with a matching year" do
    pili = people(:pili)
    post street_profile_path, params: {
      name: pili.given_name,
      favorite_year: pili.favorite_year,
      avatar_key: pili.avatar_key
    }
    assert_redirected_to root_path
    follow_redirect!
    assert_select ".street-person .word", text: pili.given_name
    assert_select "#profile_gate", count: 0
  end

  test "show opens claim when picking an away homonym" do
    pili = people(:pili)
    get street_profile_path, params: { person_id: pili.id }
    assert_response :success
    assert_select "h1", text: I18n.t("join.claim_title")
  end
end
