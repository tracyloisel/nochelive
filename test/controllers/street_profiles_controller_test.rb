require "test_helper"

class StreetProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_congregation
  end

  test "show prompts for a profile when none is signed in" do
    get street_profile_path
    assert_response :success
    assert_select "body.is-paper-hall"
    assert_select "#street_quien.profile-world"
    assert_select ".profile-panel"
    assert_select ".profile-brand", text: "Noche Live"
    assert_select "h1", text: I18n.t("street.quick_profile_title")
    assert_select ".profile-rama-current", text: wards(:demo).name
    assert_select "a.profile-rama-change[href=?]", search_path(cambiar: 1), text: I18n.t("street.change_ward_short")
    assert_select "a.profile-rama-change[aria-label=?]", I18n.t("street.change_ward")
    assert_select "a.profile-rama-change .picto", count: 0
    assert_select "h2", text: I18n.t("street.create_title")
    assert_select "label", text: I18n.t("street.create_who")
    assert_select ".join-form.profile-gate-new"
    assert_select "body[data-controller~='stage']"
    assert_select "script#noche_sfx_catalog[type='application/json']"
    assert_select ".profile-later", text: I18n.t("street.avatar_automatic")
    assert_select ".gate", count: 0
    assert_select ".story-ticks", count: 0
    assert_select ".play-reel", count: 0
  end

  test "create remembers a person on the device" do
    post street_profile_path, params: {
      name: "Nuevo",
      avatar_key: "delfin",
      favorite_year: 2010
    }
    assert_redirected_to root_path
    follow_redirect!
    assert_select ".quiz-hud-name", text: "Nuevo"
    assert_select ".toast-slot .banner[data-controller=banner]",
          text: I18n.t("flashes.street_signed_in", name: "Nuevo")
    assert_select ".banner-mark .picto-star8"
    catalog = JSON.parse(css_select("#noche_sfx_catalog").first.text)
    assert_includes catalog.keys, "notification_glint"
  end

  test "create assigns an avatar when the quick form does not choose one" do
    assert_difference("Person.count", 1) do
      post street_profile_path, params: { name: "Avatar auto" }
    end

    assert_includes Player::AVATARS, Person.order(:id).last.avatar_key
  end

  test "signed-in player can change name and avatar from the profile" do
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    follow_redirect!

    get street_profile_path(edit: 1)
    assert_response :success
    assert_select "form.profile-edit-form[action=?]", street_profile_path
    assert_select "input[name=name][value=?]", pili.given_name
    assert_select "input[name=avatar_key]", count: Player::AVATARS.size

    patch street_profile_path, params: { name: "Pilar", avatar_key: "colibri" }
    assert_redirected_to street_profile_path
    assert_equal "Pilar", pili.reload.given_name
    assert_equal "colibri", pili.avatar_key
  end

  test "profile update only works for a signed-in device profile" do
    pili = people(:pili)

    patch street_profile_path, params: { name: "Intruso", avatar_key: "gato" }

    assert_redirected_to street_profile_path
    assert_not_equal "Intruso", pili.reload.given_name
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
    assert_select ".quiz-hud-name", text: pili.given_name
    assert_select "#profile_gate", count: 0
  end

  test "show opens claim when picking an away homonym" do
    pili = people(:pili)
    get street_profile_path, params: { person_id: pili.id }
    assert_response :success
    assert_select "body.is-paper-hall"
    assert_select "h1", text: I18n.t("join.claim_title")
    assert_select "button.btn-gold", text: I18n.t("join.yes_name", name: pili.given_name)
  end

  test "ficha after desafios returns to the inbox" do
    get street_challenges_path
    assert_redirected_to street_profile_path(quick: 1, fresh: 1)
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    assert_redirected_to street_challenges_path
  end
end
