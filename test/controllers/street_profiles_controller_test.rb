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

  test "signed-in player sees the complete profile dashboard" do
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }

    get player_profile_path(pili)
    assert_response :success
    assert_select ".profile-dashboard"
    assert_select "#profile-player-name", text: pili.display_name
    assert_select "a.profile-field-row[href=?]", player_profile_path(pili, edit: "given_name"), text: /#{pili.given_name}/
    assert_select "a.profile-field-row[href=?]", player_profile_path(pili, edit: "family_name")
    assert_select "a.profile-field-row[href=?]", player_profile_path(pili, edit: "avatar_key")
    assert_select "a.profile-field-row[href=?]", player_profile_path(pili, edit: "favorite_year")
    assert_select "a.profile-field-row[href=?]", player_profile_path(pili, edit: "locale")
    assert_select ".profile-field-row.is-readonly[data-profile-field=player_id]" do
      assert_select "span", text: I18n.t("street.profile_dashboard.player_id")
      assert_select "strong", text: pili.id.to_s
    end
    assert_select ".profile-field-row.is-readonly[data-profile-field=created_at]" do
      assert_select "span", text: I18n.t("street.profile_dashboard.profile_since")
      assert_select "strong", text: I18n.l(pili.created_at.to_date, format: :default)
    end
    assert_select "a.profile-destination-card[href=?]", player_quiz_history_path(pili),
                  text: /#{Regexp.escape(I18n.t("street.profile_dashboard.answers_title"))}/
    assert_select "a.profile-destination-card[href=?]", study_history_path, text: /#{Regexp.escape(I18n.t("street.profile_dashboard.word_title"))}/
    assert_select "a.profile-destination-card[href=?]", street_challenges_path
    assert_select "a.profile-destination-card[href=?]", player_profile_path(pili, ward_next: 1)
    assert_select "a[href=?]", privacy_path
  end

  test "each canonical editor updates only the submitted field" do
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    original = pili.attributes.slice("family_name", "avatar_key", "favorite_year", "locale")

    get player_profile_path(pili, edit: "given_name")
    assert_response :success
    assert_select ".profile-editor-sheet[role=dialog][aria-modal=true]"
    assert_select "form.profile-editor-form[action=?]", player_profile_path(pili)
    assert_select "input[name=given_name][value=?]", pili.given_name

    patch player_profile_path(pili), params: { given_name: "Pilar" }
    assert_redirected_to player_profile_path(pili)
    assert_equal "Pilar", pili.reload.given_name
    assert_equal original, pili.attributes.slice("family_name", "avatar_key", "favorite_year", "locale")

    patch player_profile_path(pili), params: { avatar_key: "colibri" }
    assert_equal "colibri", pili.reload.avatar_key
    assert_equal "Pilar", pili.given_name
  end

  test "unknown editors are ignored" do
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }

    get player_profile_path(pili, edit: "admin")
    assert_response :success
    assert_select ".profile-dashboard"
    assert_select ".profile-editor-sheet", count: 0
  end

  test "every allowed profile editor opens its focused control" do
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    controls = {
      "given_name" => "input[name=given_name]",
      "family_name" => "input[name=family_name]",
      "avatar_key" => "input[name=avatar_key]",
      "favorite_year" => "input[name=favorite_year]",
      "locale" => "input[name=locale]",
      "merge" => ".profile-editor-merge"
    }

    controls.each do |editor, selector|
      get player_profile_path(pili, edit: editor)
      assert_response :success
      assert_select ".profile-editor-sheet[role=dialog][aria-modal=true]"
      assert_select selector
    end
  end

  test "family name favorite year and locale use their canonical update paths" do
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }

    patch player_profile_path(pili), params: { family_name: "Sanz" }
    assert_redirected_to player_profile_path(pili)
    assert_equal "Sanz", pili.reload.family_name

    patch player_profile_path(pili), params: { favorite_year: 1991 }
    assert_equal 1991, pili.reload.favorite_year
    assert_equal "Sanz", pili.family_name

    patch player_profile_path(pili), params: { locale: "fr" }
    assert_equal "fr", pili.reload.locale
    assert_equal 1991, pili.favorite_year
    follow_redirect!
    assert_select "h1", text: I18n.t("street.profile_dashboard.title", locale: :fr)
  end

  test "invalid profile update returns 422 and keeps the submitted value" do
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    original_name = pili.given_name

    patch player_profile_path(pili), params: { given_name: "   " }

    assert_response :unprocessable_entity
    assert_equal original_name, pili.reload.given_name
    assert_select ".profile-editor-sheet[role=dialog]"
    assert_select ".profile-editor-error[role=alert]", text: I18n.t("errors.people.name")
    assert_select "input[name=given_name][value='   '][aria-describedby~='profile-editor-error']"
  end

  test "profile update ignores an injected person and unknown attributes" do
    pili = people(:pili)
    other = people(:carmen_garcia)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }

    patch player_profile_path(pili), params: { person_id: other.id, given_name: "Pilar", admin: true }

    assert_redirected_to player_profile_path(pili)
    assert_equal "Pilar", pili.reload.given_name
    assert_equal "Carmen", other.reload.given_name
  end

  test "profile update only works for a signed-in device profile" do
    pili = people(:pili)

    patch player_profile_path(pili), params: { name: "Intruso", avatar_key: "gato" }

    assert_redirected_to street_profile_path(quick: 1)
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

  test "legacy profile gate redirects a recognized player to the explicit URL" do
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }

    get street_profile_path

    assert_redirected_to player_profile_path(pili)
  end

  test "explicit profile URL cannot expose another player from the same device" do
    pili = people(:pili)
    other = people(:carmen_garcia)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }

    get player_profile_path(other)

    assert_response :not_found
    assert_not_includes response.body, other.display_name
  end

  test "explicit profile is noindex and has no canonical search URL" do
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }

    get player_profile_path(pili)

    assert_response :success
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
    assert_select "meta[name=robots][content='noindex, nofollow']"
    assert_select "link[rel=canonical]", count: 0
  end

  test "ficha after desafios returns to the inbox" do
    get street_challenges_path
    assert_redirected_to street_profile_path(quick: 1, fresh: 1)
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    assert_redirected_to street_challenges_path
  end
end
