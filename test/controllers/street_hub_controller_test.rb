require "test_helper"

class StreetHubControllerTest < ActionDispatch::IntegrationTest
  test "hub shows world map and profile wizard on first visit" do
    get root_path
    assert_response :success
    assert_select "#street_world.street-world.is-profile-gate"
    assert_select "#profile_gate.street-wizard"
    assert_select "#profile_gate[data-controller~=keyboard-inset]"
    assert_select "#profile_gate[data-controller~=street-arrival]"
    assert_select "#profile_gate .hall-sheet"
    assert_select ".picto-btn", count: 0
    assert_select "#profile_gate[role=dialog]", count: 0
    assert_select "#ward_q"
    assert_select "#ward_picker_results"
    assert_select ".street-arrival-caption", text: I18n.t("street.gate_arrive")
    assert_select "h1", text: I18n.t("street.gate_ward_title")
    assert_select "p.lede", text: I18n.t("street.gate_ward_lede")
    assert_select ".street-arrival-lockup", text: "Noche Live"
    assert_select "#profile_gate .street-quien-rule"
    assert_select "#profile_gate .hall-sheet-apex"
    assert_no_match(/guardar tu progreso/, response.body)
    assert_select "#ward_picker_results .ward-hit", count: 1
    assert_select "#ward_picker_results .ward-hit.is-featured", text: /Rama Benidorm/
    assert_select "button.ward-picker-locate", text: I18n.t("street.gate_locate")
    assert_select "button.btn-gold", text: /Rama Benidorm/, count: 0
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
    assert_select ".street-world-dock"
    assert_select ".street-hub-nav", count: 0
    assert_select ".street-map-legend"
    assert_select ".street-map-legend .street-map-path-title"
    assert_select ".street-map-legend-rose", count: 0
    assert_select ".street-map-path-lede", count: 0
    assert_select ".street-card.is-pack.is-current .street-pack-beacon"
    assert_select ".street-card.is-pack.is-current .street-pack-coronas-label"
    assert_select ".street-map-path.is-rope .street-map-rope"
    assert_select ".street-map-track .street-card.is-pack.is-locked"
    assert_select ".street-map-track .street-card.is-pack.is-current"
    assert_select ".street-hub-nav-item", count: 0
    assert_select ".street-hub-lockup-wordmark"
    assert_select ".chrome-drawer .mute"
    assert_select ".chrome-drawer .mute .word", text: I18n.t("chrome.sound_on")
    assert_select ".chrome-drawer .lang-switch.is-drawer"
    assert_select ".chrome-drawer .lang-opt", count: 4
    assert_select ".chrome-tools", count: 0
    assert_select "#street_quiz", count: 0
    assert_select ".street-hub-lockup-star"
    assert_select ".home-menu-btn .picto-menu"
    assert_select ".home-menu.is-split .chrome-face.is-guest"
    assert_select ".home-menu.is-split .chrome-face.is-guest .picto-person"
    assert_select ".home-menu-nav"
    assert_select ".home-menu-kicker", text: I18n.t("home.ward_menu")
    assert_select ".home-menu-kicker", text: I18n.t("church.menu")
    assert_select ".home-menu-kicker", text: I18n.t("home.about_menu")
    assert_select ".home-menu-kicker", text: I18n.t("home.program"), count: 0
    assert_select "a.home-menu-row[href=?]", root_path, count: 0
    assert_select "a.home-menu-row[href=?]", jugar_path, text: I18n.t("street.menu_play")
    assert_select "a.home-menu-row[href=?]", street_history_path, text: I18n.t("street.history_menu")
    assert_select "a.home-menu-row[href=?]", street_leaderboard_path
    assert_select "a.home-menu-row[href=?]", search_path
    assert_select "a.home-menu-row[href=?]", nights_path, text: I18n.t("home.nights_menu")
    assert_select "a.home-menu-row[href=?]", search_path(cambiar: 1), count: 0
    assert_select "a.home-menu-row[href=?]", church_path
    assert_select "a.home-menu-row[href=?]", about_path
    assert_select "a.home-menu-row[href=?]", legal_path
    assert_select "a.home-menu-row[href=?]", privacy_path
    assert_select ".home-menu-block" do |blocks|
      church = blocks.find { |block| block.at_css(".home-menu-kicker")&.text&.strip == I18n.t("church.menu") }
      about = blocks.find { |block| block.at_css(".home-menu-kicker")&.text&.strip == I18n.t("home.about_menu") }
      assert church, "expected an Iglesia menu section"
      assert about, "expected a Sobre este juego menu section"
      church_hrefs = church.css("a.home-menu-row").map { |node| node["href"] }
      about_hrefs = about.css("a.home-menu-row").map { |node| node["href"] }
      assert_equal [ search_path, church_path ], church_hrefs
      assert_equal [ about_path, legal_path, privacy_path ], about_hrefs
    end
    assert_select "details.home-code"
    assert_select "details.home-code .code-input"
  end

  test "hub has no five-tab dock" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read
    refute_includes css, ".street-hub-nav"
    refute_includes css, ".street-hub-nav-item"
  end

  test "hub chrome hits are a pair of circular marble seals" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read
    hits = css[/\.chrome-face\.quiet-link,\n\.home-menu-btn\.quiet-link \{[^}]+\}/m]
    assert hits, "expected paired chrome-face and hamburger rule"
    assert_match(/border-radius: 50%/, hits)
    refute_match(/0\.75rem/, hits)
    assert_includes css, ".home-menu-btn.quiet-link.is-open"
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

  test "signed-in avatar reopens the wizard asking if this is you" do
    sign_in_congregation
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    follow_redirect!
    get root_path(ficha: 1)
    assert_response :success
    assert_select "#profile_gate"
    assert_select "h1", text: I18n.t("join.welcome_title")
    assert_select "#profile_gate .street-quien-ficha"
    assert_select "#profile_gate .street-quien-rule"
    assert_select "button.btn-gold", text: I18n.t("join.yes_name", name: pili.given_name)
    assert_select "a.btn-ghost", text: I18n.t("join.not_me")
    assert_select "a.quiet-link", text: I18n.t("street.stay_as", name: pili.given_name), count: 0
    assert_select ".profile-gate-new", count: 0
    assert_select "#gate_name", count: 0
    assert_select ".chrome-face:not(.is-guest)"
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
    assert_select ".street-league-face.is-live .street-live-dot"
    assert_select "a.home-menu-row[href=?]", search_path(cambiar: 1), count: 0
    assert_select ".home-menu-block" do |blocks|
      ward = blocks.find { |block| block.at_css(".home-menu-kicker")&.text&.strip == I18n.t("home.ward_menu") }
      assert ward, "expected a Rama menu section"
      labels = ward.css(".home-menu-label").map { |node| node.text.strip }
      assert_equal [
        I18n.t("home.nights_menu"),
        I18n.t("home.night_code")
      ], labels
    end
  end

  test "ficha param reopens profile wizard for guest" do
    sign_in_congregation
    post street_profile_path, params: { guest: 1 }
    follow_redirect!
    assert_select "#profile_gate", count: 0

    get root_path(ficha: 1)
    assert_response :success
    assert_select "#profile_gate.street-wizard"
    assert_select "#profile_gate[data-controller~=keyboard-inset]"
    assert_select ".profile-gate-new"
    assert_select "#gate_name"
    assert_select ".profile-gate-avatars .avatar-choice", count: Player::AVATARS.size
    assert_select ".profile-gate-avatars .avatar-seal", count: Player::AVATARS.size
    assert_select ".year-hint", text: I18n.t("join.year_hint")
    assert_select ".street-quien-ward", text: /#{Regexp.escape(I18n.t("street.ward_here", name: wards(:demo).city))}/
    assert_select ".street-quien-ward a.quiet-link", text: I18n.t("street.change_ward_short")
    assert_select "a.quiet-link", text: I18n.t("street.change_ward"), count: 0
    assert_select "button.quiet-link", text: I18n.t("street.continue_guest")
    assert_select "#profile_gate .hall-sheet-apex .picto-star4"
  end

  test "wizard ivory sheet keeps the night quiz gold-leaf star above the card" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read
    panel = css[/\.street-wizard-panel\.hall-sheet \{[^}]+\}/m]
    assert panel, "expected .street-wizard-panel.hall-sheet rule"
    refute_match(/overflow-y:\s*auto/, panel)
    assert_match(/overflow:\s*visible/, panel)
    star = css[/\.hall-sheet-apex::before,\n\.street-quien-apex::before \{[^}]+\}/m]
    assert star, "expected paired apex ::before star"
    assert_match(/clip-path: var\(--temple-star4\)/, star)
    assert_match(/background: var\(--temple-gold-leaf\)/, star)
    assert_match(/width: 1\.22rem/, star)
    refute_match(/\.hall-sheet::after,\n\.street-quien-sheet::after/, css)
    confirm = css[/#profile_gate \.street-wizard-panel\.hall-sheet:has\(\.street-quien-ficha\),\n\.street-quien-sheet:has\(\.street-quien-ficha\) \{[^}]+\}/m]
    assert confirm, "expected open identity confirm sheet"
    assert_match(/gap: var\(--space-5\)/, confirm)
    assert_match(/background: transparent/, confirm)
    create = css[/#profile_gate \.street-wizard-panel\.hall-sheet:has\(\.profile-gate-new\),\n\.street-quien-sheet:has\(\.profile-gate-new\) \{[^}]+\}/m]
    assert create, "expected frosted ivory create profile sheet"
    refute_match(/background:\s*transparent/, create)
    assert_match(/--temple-ivory/, create)
    assert_match(/backdrop-filter:\s*blur\(14px\)/, create)
    assert_match(/box-shadow: var\(--street-card-shadow/, create)
    refute_match(/\.street-quien-sheet:has\(\.profile-gate-new\) \.btn-ghost/, css)
    refute_match(/body\.is-street-hub:has\(#street_world\.is-profile-gate\)/, css)
    assert_match(/max-height:\s*none/, create)
    gate = css[/\.street-world\.is-profile-gate \{[^}]+\}/m]
    assert gate, "expected .street-world.is-profile-gate rule"
    assert_match(/overflow:\s*visible/, gate)
    assert_match(/height:\s*auto/, gate)
    assert_match(/max-height:\s*none/, gate)
    html_scroll = css[/html:has\(#profile_gate\),\nbody:has\(#profile_gate\) \{[^}]+\}/m]
    assert html_scroll, "expected document scroll while the profile gate is open"
    assert_match(/overflow-y:\s*auto/, html_scroll)
    reduced = css.split("@media (prefers-reduced-transparency: reduce)", 2).last
    assert reduced, "expected solid ivory fallback when transparency is reduced"
    assert_match(/backdrop-filter:\s*none/, reduced)
    assert_match(/--temple-ivory/, reduced)
    clearance = css[/#profile_gate\.street-wizard\.is-ready:has\(\.profile-gate-new\),\n#profile_gate\.street-wizard\.is-ready:has\(\.profile-gate-people\) \{[^}]+\}/m]
    assert clearance, "expected create/device wizard to start below the chrome"
    assert_match(/justify-content:\s*flex-start/, clearance)
    assert_match(/padding-top:\s*calc\(4\.75rem \+ env\(safe-area-inset-top\)\)/, clearance)
    refute_match(/--space-5/, clearance)
  end

  test "wizard asks not me before listing other device fichas then create" do
    sign_in_congregation
    pili = people(:pili)
    carmen = people(:carmen_garcia)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    follow_redirect!
    token = PersonDevice.where(person: pili).order(:id).last.device_token
    PersonDevice.create!(person: carmen, device_token: token, last_seen_at: Time.current)

    get root_path(ficha: 1)
    assert_select "h1", text: I18n.t("join.welcome_title")
    assert_select "button.btn-gold", text: I18n.t("join.yes_name", name: pili.given_name)
    assert_select "#gate_name", count: 0
    assert_select ".profile-gate-people", count: 0

    get root_path(ficha: 1, not_me: 1)
    assert_select "h1", text: I18n.t("join.device_title")
    assert_select ".profile-gate-people .person-pick", count: 1
    assert_select ".profile-gate-people strong", text: carmen.given_name
    assert_select "a.btn-ghost", text: I18n.t("join.none_of_these")
    assert_select "#gate_name", count: 0

    get root_path(ficha: 1, fresh: 1)
    assert_select "h1", text: I18n.t("street.create_title")
    assert_select "p.lede", text: I18n.t("street.create_lede")
    assert_select "label", text: I18n.t("street.create_who")
    assert_select "legend", text: I18n.t("street.create_animal")
    assert_select "#gate_name"
    assert_select ".profile-gate-new"
    assert_select ".profile-gate-people", count: 0
  end

  test "unsigned device with one ficha asks is this you not create" do
    sign_in_congregation
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    follow_redirect!
    post street_profile_path, params: { guest: 1 }
    follow_redirect!

    get root_path(ficha: 1)
    assert_response :success
    assert_select "h1", text: I18n.t("join.welcome_title")
    assert_select "button.btn-gold", text: I18n.t("join.yes_name", name: pili.given_name)
    assert_select "#gate_name", count: 0
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

  test "challenger hub shows waiting after a scored challenge" do
    sign_in_congregation
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    follow_redirect!
    street_duels(:pending_challenge).update!(status: "challenger_done", challenger_score: 80)
    get root_path
    assert_select ".street-duel-banner"
    assert_select ".street-duel-accept", text: I18n.t("street.duel_share_again")
    assert_select "form[action=?]", street_challenge_accept_path(street_duels(:pending_challenge).token), count: 0
  end

  test "named waiting hub does not offer a share link" do
    sign_in_congregation
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    follow_redirect!
    StreetDuel.create!(
      challenger_person: pili,
      opponent_person: people(:carmen_garcia),
      ward: wards(:demo),
      pack_id: "coronas",
      token: "hub-named-wait",
      status: "challenger_done",
      challenger_score: 81,
      expires_at: 7.days.from_now
    )
    get root_path
    assert_select ".street-duel-banner"
    assert_select ".street-duel-accept", count: 0
    assert_select "a.quiet-link", text: I18n.t("street.duel_inbox_open")
    assert_select ".street-duel-banner-lede", text: I18n.t("street.duel_waiting_named", name: people(:carmen_garcia).display_name)
  end
end
