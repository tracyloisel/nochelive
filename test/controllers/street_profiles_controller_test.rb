require "test_helper"

class StreetProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_congregation
  end

  test "show prompts for a profile when none is signed in" do
    get street_profile_path
    assert_response :success
    assert_select "body.is-paper-hall"
    assert_select "#street_quien.street-quien"
    assert_select ".street-quien-sheet"
    assert_select ".street-hub-lockup-name", text: "Noche Live"
    assert_select ".street-hub-kicker", text: I18n.t("street.profile_title")
    assert_select "h1", text: I18n.t("street.create_title")
    assert_select "p.lede", text: I18n.t("street.create_lede")
    assert_select "label", text: I18n.t("street.create_who")
    assert_select "legend", text: I18n.t("street.create_animal")
    assert_select ".profile-gate-new"
    assert_select ".gate", count: 0
    assert_select ".story-ticks", count: 0
    assert_select ".play-reel", count: 0
  end

  test "show welcomes a person already on this device" do
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    follow_redirect!
    get street_profile_path
    assert_response :success
    assert_select "body.is-paper-hall"
    assert_select "#street_quien"
    assert_select "h1", text: I18n.t("join.welcome_title")
    assert_select ".street-quien-ficha"
    assert_select ".street-quien-apex"
    assert_select "form[action=?]", street_profile_path do
      assert_select "button.btn-gold", text: I18n.t("join.yes_name", name: pili.given_name)
    end
    assert_select "a.btn-ghost", text: I18n.t("join.not_me")
    assert_select "a.quiet-link", text: I18n.t("street.change_ward_short")
    assert_select ".street-quien-ward", text: /#{Regexp.escape(I18n.t("street.ward_here", name: wards(:demo).city))}/
    assert_select ".gate", count: 0
    assert_select ".picto-btn", count: 0
  end

  test "fresh form keeps a quiet signed-in line without a second ficha" do
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    follow_redirect!
    get street_profile_path, params: { fresh: 1 }
    assert_response :success
    assert_select "h1", text: I18n.t("street.create_title")
    assert_select ".street-quien-session", text: /#{Regexp.escape(pili.given_name)}/
    assert_select ".street-quien-ficha", count: 0
    assert_select "button.btn-ghost", count: 0
    assert_select ".join-form"
    assert_select ".street-quien-foot button", text: I18n.t("street.continue_guest")
    assert_select ".street-quien-foot a", text: I18n.t("street.back_quiz")
  end

  test "create remembers a person on the device" do
    post street_profile_path, params: {
      name: "Nuevo",
      avatar_key: "delfin",
      favorite_year: 2010
    }
    assert_redirected_to root_path
    follow_redirect!
    assert_select ".street-card-name", text: "Nuevo"
    assert_select ".toast-slot .banner[data-controller=banner]",
          text: I18n.t("flashes.street_signed_in", name: "Nuevo")
    assert_select ".banner-mark .picto-star8"
  end

  test "guest clears the street profile and closes the gate" do
    post street_profile_path, params: {
      name: "Nuevo",
      avatar_key: "delfin",
      favorite_year: 2010
    }
    follow_redirect!
    assert_select ".street-card-name", text: "Nuevo"

    post street_profile_path, params: { guest: 1 }
    assert_redirected_to root_path
    follow_redirect!
    assert_select ".street-card-name", text: I18n.t("street.pick_profile")
    assert_select "#profile_gate", count: 0
    assert_select "#street_world"
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
    assert_select ".street-card-name", text: pili.given_name
    assert_select "#profile_gate", count: 0
  end

  test "show lists other device people after not me" do
    pili = people(:pili)
    carmen = people(:carmen_garcia)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    follow_redirect!
    token = PersonDevice.where(person: pili).order(:id).last.device_token
    PersonDevice.create!(person: carmen, device_token: token, last_seen_at: Time.current)

    get street_profile_path
    assert_response :success
    assert_select "h1", text: I18n.t("join.welcome_title")
    assert_select "a.btn-ghost", text: I18n.t("join.not_me")
    assert_select ".street-quien-sheet .join-form", count: 0

    get street_profile_path, params: { not_me: 1 }
    assert_response :success
    assert_select "h1", text: I18n.t("join.device_title")
    assert_select "#street_quien .street-quien-sheet .person-list .person-pick", count: 1
    assert_select ".person-list strong", text: carmen.given_name
    assert_select "a.btn-ghost", text: I18n.t("join.none_of_these")
    assert_select ".street-quien-sheet .join-form", count: 0
    assert_select ".gate", count: 0
  end

  test "show opens claim when picking an away homonym" do
    pili = people(:pili)
    get street_profile_path, params: { person_id: pili.id }
    assert_response :success
    assert_select "body.is-paper-hall"
    assert_select "#street_quien .street-quien-sheet"
    assert_select "h1", text: I18n.t("join.claim_title")
    assert_select "button.btn-gold", text: I18n.t("join.yes_name", name: pili.given_name)
  end

  test "guest cannot skip a pending challenge" do
    duel = street_duels(:pending_challenge)
    post street_challenge_accept_path(duel.token)
    post street_profile_path, params: { guest: 1 }
    assert_redirected_to root_path(ficha: 1, desafio: duel.token)
  end

  test "ficha after desafios returns to the inbox" do
    get street_challenges_path
    assert_redirected_to root_path(ficha: 1)
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    assert_redirected_to street_challenges_path
  end
end
