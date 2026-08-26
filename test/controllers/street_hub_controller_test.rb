require "test_helper"

class StreetHubControllerTest < ActionDispatch::IntegrationTest
  test "hub shows world map and profile wizard on first visit" do
    get root_path
    assert_response :success
    assert_select "#street_world.street-world.is-profile-gate"
    assert_select "#profile_gate.street-wizard"
    assert_select ".street-card.is-player"
    assert_select ".street-map-path"
    assert_select ".street-card.is-pack.is-current"
    assert_select ".street-map-path.is-rope"
    assert_select ".street-world .street-card.is-pack", maximum: 3
    assert_select ".street-pack-soon", text: /próximamente/i
    assert_select ".street-play-cta"
    assert_select ".street-play-cta.picto-btn", count: 0
    assert_select ".street-hub-nav"
    assert_select ".street-temple-pill"
    assert_select ".street-map-legend"
    assert_select ".street-map-legend-rose"
    assert_select ".street-map-path.is-rope .street-map-rope"
    assert_select ".street-map-track .street-card.is-pack.is-locked"
    assert_select ".street-map-track .street-card.is-pack.is-current"
    assert_select ".street-hub-nav-item", count: 5
    assert_select "#street_quiz", count: 0
    assert_select ".street-hub-lockup-star"
    assert_select ".home-menu-btn .picto-gear"
    assert_select ".home-menu-nav"
    assert_select ".home-menu-me.is-guest", text: I18n.t("street.pick_profile")
    assert_select ".home-menu-kicker", text: I18n.t("home.program")
    assert_select "a.home-menu-row[href=?]", root_path, count: 0
    assert_select "a.home-menu-row[href=?]", street_history_path, text: I18n.t("street.history_menu")
    assert_select "a.home-menu-row[href=?]", search_path
    assert_select "a.home-menu-row[href=?]", nights_path
    assert_select "a.home-menu-row[href=?]", about_path
    assert_select "details.home-code"
    assert_select "details.home-code .code-input"
  end

  test "guest mode hides profile wizard and league" do
    sign_in_congregation
    post street_profile_path, params: { guest: 1 }
    follow_redirect!
    assert_select "#profile_gate", count: 0
    assert_select ".street-league", count: 0
    assert_select ".street-map-path"
  end

  test "camino redirects to hub historial anchor" do
    get street_history_path
    assert_response :success
    get "/camino"
    assert_redirected_to "/#historial"
  end

  test "unlock param wires packUnlock motion on target pack" do
    next_pack = QuizDefinition.catalog.pack_ids.second
    get root_path(unlock: next_pack)
    assert_response :success
    assert_select "#pack-#{next_pack}[data-street-motion-sequence-value='packUnlock']"
    assert_select "#pack-#{next_pack}.is-unlocking.is-locked"
  end

  test "invalid unlock param is ignored" do
    get root_path(unlock: "not-a-pack")
    assert_response :success
    assert_select "[data-street-motion-sequence-value='packUnlock']", count: 0
  end

  test "hub shows league see-all link when signed in" do
    sign_in_congregation
    pili = people(:pili)
    QuizRun.create!(
      device_digest: "hub-league",
      person: pili,
      pack_id: "coronas",
      position: 10,
      score: 55,
      status: "finished",
      opened_at: Time.current
    )
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    follow_redirect!
    assert_select "a.street-league[href=?]", street_leaderboard_path
    assert_select ".street-league-head h2", text: /liga/i
    assert_select ".street-league-all", text: /clasificación/i
  end

  test "ficha param reopens profile wizard for guest" do
    sign_in_congregation
    post street_profile_path, params: { guest: 1 }
    follow_redirect!
    assert_select "#profile_gate", count: 0

    get root_path(ficha: 1)
    assert_response :success
    assert_select "#profile_gate.street-wizard"
  end

  test "pending duel banner from desafio param" do
    duel = street_duels(:pending_challenge)
    get root_path(desafio: duel.token)
    assert_response :success
    assert_select ".street-duel-banner"
    assert_select ".street-duel-vs-mark", text: "VS"
    assert_select "form[action=?]", street_challenge_accept_path(duel.token)
  end
end
