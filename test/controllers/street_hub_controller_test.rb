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
    assert_select ".street-world .street-card.is-pack", count: QuizDefinition.catalog.pack_ids.size
    assert_select ".street-map-path.is-rope .street-map-rope", count: QuizDefinition.catalog.pack_ids.size - 1
    assert_select ".street-pack-replay", count: 0
    assert_select ".street-pack-soon", text: /próximamente/i
    assert_select ".street-play-cta"
    assert_select ".street-play-cta.picto-btn", count: 0
    assert_select ".street-pack-play", count: 0
    assert_select ".street-pack-play-wrap", count: 0
    assert_select ".street-hub-nav"
    assert_select ".street-temple-pill"
    assert_select ".street-map-legend"
    assert_select ".street-map-legend .street-map-path-title"
    assert_select ".street-map-legend-rose", count: 0
    assert_select ".street-map-path-lede", count: 0
    assert_select ".street-card.is-pack.is-current .street-pack-beacon"
    assert_select ".street-card.is-pack.is-current .street-pack-coronas-label"
    assert_select ".street-map-path.is-rope .street-map-rope"
    assert_select ".street-map-track .street-card.is-pack.is-locked"
    assert_select ".street-map-track .street-card.is-pack.is-current"
    assert_select ".street-hub-nav-item", count: 5
    assert_select ".street-hub-nav-ico", count: 5
    assert_select ".street-hub-lockup-wordmark"
    assert_select ".chrome-tools .mute"
    assert_select ".chrome-tools .mute + .lang-switch"
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

  test "hub dock tabs use ink and a gold active disc" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read
    nav = css[/\.street-hub-nav-item \{[^}]+\}/m]
    assert nav, "expected .street-hub-nav-item rule"
    assert_match(/color: var\(--ink\)/, nav)
    refute_match(/48%/, nav)
    refute_match(/42%/, nav)
    assert_includes css, ".street-hub-nav-item.is-active .street-hub-nav-ico"
    assert_includes css, "background: var(--temple-gold-leaf"
    soon = css[/\.street-hub-nav-item\.is-soon \{[^}]+\}/m]
    assert soon, "expected .street-hub-nav-item.is-soon rule"
    refute_match(/opacity: 0\.42/, soon)
    assert_match(/color: var\(--parchment\)/, soon)
  end

  test "hub rope map chrome matches temple mockup" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read
    rope_track = css[/\.street-map-path\.is-rope \.street-map-track \{[^}]+\}/m]
    assert rope_track, "expected .street-map-path.is-rope .street-map-track rule"
    assert_match(/background: none/, rope_track)

    legend = css[/\.street-map-legend \{[^}]+\}/m]
    assert legend, "expected .street-map-legend rule"
    refute_match(/clip-path/, legend)
    assert_match(/border-radius: 0\.5rem/, legend)

    coronas = css[/\.street-map-path\.is-rope \.street-card\.is-pack\.is-current \.street-pack-coronas-label \{[^}]+\}/m]
    assert coronas, "expected current coronas pill rule"
    assert_match(/border-radius: 999px/, coronas)
    refute_match(/clip-path/, coronas)

    beacon = css[/\.street-map-path\.is-rope \.street-card\.is-pack\.is-current \.street-pack-beacon \{[^}]+\}/m]
    assert beacon, "expected current star pointer rule"
    assert_match(/clip-path: var\(--temple-star4\)/, beacon)
    refute_match(/animation: beacon-bob/, beacon)

    rope = css[/\.street-map-path\.is-rope \.street-map-rope \{[^}]+\}/m]
    assert rope, "expected helix rope rule"
    assert_match(/height: 4\.25rem/, rope)

    path = css[/\.street-map-path\.is-rope \{[^}]+\}/m]
    assert path, "expected scrollable rope path"
    assert_match(/overflow-y: auto/, path)

    titles = css[/\.street-map-path\.is-rope \.street-pack-title \{[^}]+\}/m]
    assert titles, "expected pack title rule"
    assert_match(/white-space: nowrap/, titles)

    league = css[/\.street-world:not\(\.street-leaderboard-page\) \.street-league \{[^}]+\}/m]
    assert league, "expected hub league rule"
    assert_match(/flex-shrink: 0/, league)
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

  test "unlock param wires packUnlock motion on a locked pack" do
    next_pack = QuizDefinition.catalog.pack_ids.second
    get root_path(unlock: next_pack)
    assert_response :success
    assert_select "#pack-#{next_pack}[data-street-motion-sequence-value='packUnlock']"
    assert_select "#pack-#{next_pack}.is-unlocking.is-locked"
    assert_select ".street-pack-play", count: 0
    assert_select ".street-pack-play-wrap", count: 0
  end

  test "unlock param on the current pack does not replay the lock" do
    current = QuizDefinition.catalog.pack_ids.first
    get root_path(unlock: current)
    assert_response :success
    assert_select "#pack-#{current}.is-current"
    assert_select "#pack-#{current}.is-unlocking", count: 0
    assert_select "#pack-#{current}.is-locked", count: 0
    assert_select "[data-street-motion-sequence-value='packUnlock']", count: 0
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

  test "rank_up param plays level_up once from stage_sfx" do
    get root_path(rank_up: 1)
    assert_response :success
    assert_select "#street_world[data-stage-sfx-value=level_up]"
    assert_select "#street_world[data-stage-sfx-token-value^='hub:rank_up:']"
    assert_select "[data-street-hub-rank-up-value]", count: 0
  end

  test "finished pack is replayable without a gold node CTA" do
    sign_in_congregation
    post street_profile_path, params: { guest: 1 }
    follow_redirect!
    post street_pack_start_path("coronas")
    follow_redirect!
    run = QuizRun.open_runs.order(:id).last
    run.update!(position: 10)
    Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)
    Quizzes::Complete.call(run: run.reload)

    get root_path
    assert_response :success
    assert_select ".street-world .street-card.is-pack", count: QuizDefinition.catalog.pack_ids.size
    assert_select "#pack-coronas.is-finished .street-pack-replay-form"
    assert_select "#pack-coronas .street-pack-replay", text: I18n.t("street.pack_replay")
    assert_select ".street-pack-play", count: 0
    assert_select ".street-card.is-pack.is-locked .street-pack-replay", count: 0
    assert_select ".street-play-cta"

    post street_pack_start_path("coronas")
    follow_redirect!
    assert_select "#street_quiz"
    replay = QuizRun.open_runs.order(:id).last
    assert replay
    assert_equal "coronas", replay.pack_id
    assert_not_equal run.id, replay.id
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
