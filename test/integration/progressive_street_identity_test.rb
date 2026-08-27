require "test_helper"

class ProgressiveStreetIdentityTest < ActionDispatch::IntegrationTest
  test "a first visitor gets the complete hub and a profile invitation" do
    get root_path

    assert_response :success
    assert_select "#profile_gate", count: 0
    assert_select ".street-hub-feed"
    assert_select ".street-hub-nav"
    assert_select "a.quiz-hud-who.is-guest[href=?]", street_profile_path(fresh: 1)
    assert_select ".hub-live.is-ward_missing"
    assert_select ".hub-live.is-ward_missing[data-hub-live-theme=dark]"
    assert_select "a.hub-live-program.is-ward-pick[href=?]",
      street_profile_path(quick: 1, fresh: 1, ward_next: 1),
      text: I18n.t("hub.pick_ward_cta")
    assert_select ".hub-live-ward-title", text: I18n.t("hub.pick_ward_title")
    assert_select ".hub-live-ward-promises li", count: 3
  end


  test "ward invitation creates a named profile before opening ward discovery" do
    get street_profile_path(quick: 1, fresh: 1, ward_next: 1)
    assert_response :success
    assert_select "h1", text: I18n.t("street.quick_profile_title")

    assert_difference -> { Person.count }, 1 do
      post street_profile_path(quick: 1, ward_next: 1), params: { name: "Lina", avatar_key: "delfin" }
    end

    assert_redirected_to search_path(cambiar: 1)
    assert_equal "Lina", Person.order(:id).last.given_name
  end

  test "social hub tiles ask a player without a ward to choose one" do
    post street_profile_path, params: { name: "Lina", avatar_key: "delfin" }
    assert_redirected_to root_path
    follow_redirect!

    assert_select ".hub-challenge.is-ward-required .hub-challenge-empty-hint", text: I18n.t("hub.challenge_pick_ward")
    assert_select ".hub-challenge.is-ward-required a[href=?]", search_path(cambiar: 1), text: I18n.t("hub.pick_ward_action")
    assert_select ".hub-online .hub-online-ward-required .hub-online-empty", text: I18n.t("hub.online_pick_ward")
    assert_select ".hub-online .hub-online-ward-required a[href=?]", search_path(cambiar: 1), text: I18n.t("hub.pick_ward_action")
    assert_select ".hub-online a[href=?]", street_leaderboard_path, count: 0
  end

  test "the hub paints one preloaded narrative background" do
    get root_path

    assert_response :success
    assert_select "body.is-game-hub-page"
    assert_select "#street_world.is-opening", count: 0
    assert_select "#street_world[data-controller~='hub-open']", count: 0
    assert_select ".hub-hero[data-controller~='hub-hero']", count: 0
    assert_select ".hub-hero-stage > .hub-dots[data-hub-voyage-target='dots']", count: 1
    assert_select "link[rel=preload][as=image]", count: 1

    css = Rails.root.join("app/assets/stylesheets/application.css").read
    hub_sky = css[/body\.is-street-hub\.is-game-hub-page \.sky \{[^}]+\}/m]
    assert hub_sky
    assert_match(/background:\s*none/, hub_sky)
    refute_match(/\.street-world\.is-game-hub\.is-opening::before\s*\{[^}]*opacity:\s*0/m, css)
    ward_live = css[/\.street-world\.is-game-hub \.hub-live\.is-ward_missing \{[^}]+\}/m]
    assert ward_live
    assert_match(/min-height:\s*8\.25rem/, ward_live)
    refute_match(/\.is-opening \.hub-live,/, css)

    opening = Rails.root.join("app/javascript/controllers/hub_open_controller.js").read
    refute_includes opening, "is-background-arriving"

    refute_match(/\.hub-slide\.is-current \.hub-slide-still\s*\{[^}]*animation:/m, css)
    refute_match(/\.hub-reward-chest\.is-sheening/, css)
    refute_match(/\.hub-play\.is-idle-sheen/, css)
    dots = css[/\.hub-dots \{[^}]+\}/m]
    assert dots
    assert_match(/position:\s*absolute/, dots)
    assert_match(/bottom:\s*var\(--space-3\)/, dots)
  end

  test "playing asks only for a name then resumes the requested pack" do
    post street_pack_start_path("coronas")

    assert_redirected_to street_profile_path(quick: 1, fresh: 1)
    follow_redirect!
    assert_select "h1", text: I18n.t("street.quick_profile_title")
    assert_select "input[name=name]"
    assert_select "input[name=avatar_key][type=hidden]"
    assert_select "input[name=favorite_year]", count: 0
    assert_select ".avatar-pick", count: 0

    assert_difference -> { Person.count }, 1 do
      post street_profile_path(quick: 1), params: { name: "Noa", avatar_key: "delfin" }
    end

    person = Person.order(:id).last
    assert_nil person.ward
    assert_nil person.favorite_year
    assert_redirected_to jugar_path
    follow_redirect!
    assert_select "#street_quiz"
    assert_equal person.id, QuizRun.order(:id).last.person_id
  end
end
