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
    assert_select "#ward_picker_results .ward-hit", count: 0
    assert_select "#ward_picker_results .ward-hit.is-featured", count: 0
    assert_select "button.ward-picker-locate", text: I18n.t("street.gate_locate")
    assert_select "button.btn-gold", text: /Rama Benidorm/, count: 0
    assert_select ".quiz-hud", count: 0
    assert_select ".street-hub-feed"
    assert_select ".hub-hero"
    assert_select ".hub-hero-stage"
    assert_select ".hub-slide-copy"
    assert_select ".hub-hero-continue", text: I18n.t("hub.continue")
    assert_select "h2.hub-hero-title.street-map-door-kicker",
      text: QuizDefinition.catalog.find_pack("coronas").copy(:kicker)
    assert_select ".street-map-door-step", text: I18n.t("hub.step", n: 1, total: 10)
    assert_select ".hub-hero-name.street-map-door-pack",
      text: QuizDefinition.catalog.find_pack("coronas").copy(:title)
    assert_select ".street-map-door-lede", text: QuizDefinition.catalog.find_pack("coronas").copy(:lede)
    assert_select ".hub-reward-label", text: I18n.t("hub.reward")
    assert_select ".hub-reward img.hub-reward-chest[src=?]", "/media/temple/reward-chest.png"
    assert_select ".hub-reward .picto-chest", count: 0
    assert_select ".hub-reward-value", text: "+#{QuizDefinition::CURVE_POINTS.sum}"
    assert_select ".hub-hero-info .picto-info"
    assert_select ".street-card.is-map-door", count: 1
    assert_select ".hub-play", text: I18n.t("street.world_play")
    assert_select "a.street-map-door-open", count: 0
    assert_select "#street_world .street-map-path", count: 0
    assert_select "#street_world .street-card.is-pack", count: 0
    assert_select ".street-pack-replay", count: 0
    assert_select ".street-play-cta", count: 0
    assert_select ".street-pulse", count: 0
    assert_select ".street-world-dock", count: 0
    assert_select ".street-pack-play", count: 0
    assert_select ".street-pack-play-wrap", count: 0
    assert_select ".street-hub-nav", count: 0
    assert_select ".street-friend-rail", count: 0
    assert_select ".street-map-legend", count: 0
    assert_select ".street-pack-beacon", count: 0
    assert_select ".street-hub-nav-item", count: 0
    assert_select ".chrome-drawer .mute"
    assert_select ".chrome-drawer .mute .word", text: I18n.t("chrome.sound_on")
    assert_select ".chrome-drawer .lang-switch.is-drawer"
    assert_select ".chrome-drawer .lang-opt", count: 4
    assert_select ".chrome-tools", count: 0
    assert_select "#street_quiz", count: 0
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
    assert_select "a.home-menu-row[href=?]", street_map_path, text: I18n.t("street.world_map")
    assert_select "a.home-menu-row[href=?]", street_history_path, text: I18n.t("street.history_menu")
    assert_select "a.home-menu-row[href=?]", street_leaderboard_path
    assert_select "a.home-menu-row[href=?]", search_path
    assert_select "a.home-menu-row[href=?]", search_path(cambiar: 1), count: 0
    assert_select "a.home-menu-row[href=?]", church_path
    assert_select "a.home-menu-row[href=?]", about_path
    assert_select "a.home-menu-row[href=?]", platform_stats_path, text: I18n.t("stats.menu")
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
      assert_equal [ about_path, platform_stats_path, legal_path, privacy_path ], about_hrefs
    end
    assert_select "details.home-code"
    assert_select "details.home-code .code-input"
  end

  test "about menu lists cifras between who and legal" do
    get root_path
    assert_response :success
    assert_select ".home-menu-block" do |blocks|
      about = blocks.find { |block| block.at_css(".home-menu-kicker")&.text&.strip == I18n.t("home.about_menu") }
      assert about, "expected a Sobre este juego menu section"
      about_hrefs = about.css("a.home-menu-row").map { |node| node["href"] }
      assert_equal [ about_path, platform_stats_path, legal_path, privacy_path ], about_hrefs
    end
  end

  test "hub five-tab dock is in the game-hub CSS" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read
    assert_includes css, ".street-hub-nav"
    assert_includes css, ".street-hub-nav-item"
  end

  test "game hub HUD is the quiz capsule on the artwork" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read
    hud = css[/body\.is-street-hub:has\(\.street-world\.is-game-hub:not\(\.is-profile-gate\)\) \.home-menu\.is-hud \{[^}]+\}/m]
    assert hud, "expected the hub chrome HUD rule"
    assert_includes css, ".street-world > .home-menu"
    assert_includes css, ".home-menu.is-hud .quiz-hud"
    assert_includes css, 'grid-template-areas: "who level pack stats menu"'
    assert_includes css, ".quiz-hud-rank .quiz-hud-level"
    assert_includes css, ".quiz-hud.is-guest"
    assert_includes css, ".quiz-hud-cta"
    refute_includes css, ".hub-mini.is-on .hub-mini-bar"
    refute_includes css, ".hub-hud.is-away"
    assert_includes css, ".hub-rail.is-empty"
    assert_includes css, ".hub-live.is-empty"
    assert_includes css, ".hub-live-digit"
    assert_includes css, ".hub-live-colon"
    assert_includes css, '[data-hub-live-theme="light"]'
    assert_includes css, '[data-hub-live-theme="dark"]'
    assert_includes css, ".hub-live.is-still::after"
    light_theme = css[/\.hub-live\[data-hub-live-theme="light"\] \{[^}]+\}/m]
    dark_theme = css[/\.hub-live\[data-hub-live-theme="dark"\] \{[^}]+\}/m]
    assert light_theme, "expected Celestial Light live-card tokens"
    assert dark_theme, "expected Celestial Dark live-card tokens"
    assert_match(/--hub-live-art-wash:\s*linear-gradient\(\s*90deg,/, light_theme)
    assert_match(/--hub-live-art-wash:\s*linear-gradient\(\s*90deg,/, dark_theme)
    assert_match(/background:\s*var\(--hub-live-art-wash\)/, css)
    refute_match(/\.street-world\.is-game-hub \.hub-live \{\s*--hub-live-paper: var\(--temple-ivory/, css)
    assert_includes css, ".hub-panel"
    assert_includes css, "grid-template-columns: 1fr 1fr"
    assert_includes css, "--text-on-glass"
    assert_includes css, "--text-on-gold"
    assert_includes css, "--text-on-light-surface"
    assert_includes css, "--text-on-dark-surface"
    assert_includes css, ".street-world.is-game-hub .hub-community .street-pulse-month"
    assert_match(/var\(--text-on-glass\)/, css[/\.street-world\.is-game-hub \.hub-community \.street-pulse-month[\s\S]+?color:[^;]+/])
    assert_includes css, ".street-world.is-game-hub:not(.street-leaderboard-page) a.street-league"
    assert_includes css, "a.hub-text-go"
    reward = css[/\.hub-reward \{[^}]+\}/m]
    assert reward, "expected .hub-reward prize pill"
    assert_match(/--hub-reward-paper/, reward)
    assert_match(/border-radius: var\(--radius-pill\)/, reward)
    assert_match(/max-width: 7\.5rem/, reward)
    assert_match(/min-height: 2\.45rem/, reward)
    actions = css[/\.hub-hero-actions \{[^}]+\}/m]
    assert actions, "expected centered hero actions"
    assert_match(/align-items: center/, actions)
    play = css[/\.street-world\.is-game-hub \.hub-play\.street-map-door-play,\n\.street-world\.is-game-hub \.hub-play \{[^}]+\}/m]
    assert play, "expected dominant Jouer control"
    assert_match(/min-width: 8\.1rem/, play)
    assert_match(/min-height: 2\.85rem/, play)
    chest = css[/\.hub-reward-chest \{[^}]+\}/m]
    assert chest, "expected compact reward chest"
    assert_match(/width: 2\.7rem/, chest)
    assert_match(/height: 2rem/, chest)
    refute_includes css, ".hub-hero.is-copy-arriving"
    refute_match(/\.hub-reward \{[^}]+border: 1px solid var\(--border-gold\)/m, css)
    refute_match(/\.hub-reward \{[^}]+var\(--text-primary\)/m, css)
    refute_match(/\.street-world\.is-game-hub:not\(\.street-leaderboard-page\) a\.street-league[\s\S]{0,400}min-height:\s*5rem/, css)
  end

  test "online tile shows two real friends ranks crowns and leaderboard CTA" do
    PersonDevice.where(person: people(:carmen_garcia)).update_all(last_seen_at: Time.current)
    PersonDevice.create!(
      person: people(:carmen_lopez),
      device_token: "hub-online-carmen-lopez",
      last_seen_at: Time.current
    )
    sign_in_congregation
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    follow_redirect!

    assert_select "article.hub-online:not(.is-empty)"
    assert_select ".hub-online-head .hub-kicker", text: I18n.t("hub.online")
    assert_select ".hub-online-count", text: I18n.t("hub.online_count", count: 2)
    assert_select ".hub-online-row", count: 2
    assert_select ".hub-online-face img.avatar-img", count: 2
    assert_select ".hub-online-name", text: people(:carmen_garcia).given_name
    assert_select ".hub-online-stats", text: I18n.t("hub.online_meta", count: 208, crowns: 208)
    assert_select ".hub-online-presence .street-live-dot", count: 2
    assert_select "a.hub-online-ranking[href=?]", street_leaderboard_path,
      text: /#{Regexp.escape(I18n.t("hub.see_ranking"))}/
    assert_select "a.hub-online-ranking .picto-podium"
  end

  test "online tile CSS has isolated Light and Dark surfaces with vivid presence" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read
    tile = css[/\.street-world\.is-game-hub \.hub-online \{[^}]+\}/m]
    assert tile, "expected isolated online tile rule"
    refute_match(%r{grid-column: 1 / -1}, tile)
    assert_includes css, "--hub-online-live: #31bd65"
    assert_includes css, '.street-world.is-game-hub[data-hub-theme="light"] .hub-online'
    assert_includes css, '.street-world.is-game-hub[data-hub-theme="dark"] .hub-online'
    assert_includes css, ".street-world.is-game-hub .hub-online-presence .street-live-dot"
    assert_includes css, ".street-world.is-game-hub .hub-online-ranking"
    assert_match(/\.street-world\.is-game-hub \.hub-online \{[^}]+align-self: start/m, css)
    assert_match(/\.street-world\.is-game-hub \.hub-online-head \{[^}]+flex-direction: row/m, css)
    assert_match(/\.street-world\.is-game-hub \.hub-online-list \{[^}]+flex: none/m, css)
  end

  test "community tile CSS uses readable stat rows with two-line labels in Light and Dark" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read
    stats = css[/\.hub-community-stats \{[^}]+\}/m]
    assert stats, "expected .hub-community-stats"
    assert_match(/grid-template-columns: 1fr/, stats)

    tile = css[/\.street-world\.is-game-hub \.hub-community \{[^}]+\}/m]
    assert tile, "expected full-width community tile"
    refute_match(%r{grid-column: 1 / -1}, tile)

    label = css[/\.hub-community-label \{[^}]+\}/m]
    assert label, "expected .hub-community-label"
    assert_match(/display: block/, label)
    assert_match(/font-size: var\(--type-min\)/, label)
    label_line = css[/\.hub-community-label span \{[^}]+\}/m]
    assert_match(/white-space: nowrap/, label_line)

    light_label = css[/\.street-world\.is-game-hub\[data-hub-theme="light"\] \.hub-community-label \{[^}]+\}/m]
    assert light_label, "expected Light small-caps community labels"
    assert_match(/text-transform: uppercase/, light_label)

    assert_includes css, ".street-world.is-game-hub[data-hub-theme=\"dark\"] .hub-community-n"
    assert_includes css, ".street-world.is-game-hub[data-hub-theme=\"dark\"] .hub-community-mark-gold"
    assert_includes css, ".street-world.is-game-hub[data-hub-theme=\"light\"] .hub-community-stats li + li"
    assert_includes css, ".hub-community-mark .hub-community-mark-gold { display: none; }"
    assert_includes css, ".hub-community-mark .hub-community-mark-ink { display: block; }"
    refute_includes css, ".hub-community-stats li .picto"
  end

  test "community tile shows live pulse, two-line labels, and gold/ink icons" do
    sign_in_congregation
    post street_profile_path, params: { guest: 1 }
    follow_redirect!
    assert_select ".hub-community .hub-kicker", text: I18n.t("hub.community")
    assert_select ".hub-community a.street-pulse[href=?]", platform_stats_path
    assert_select ".hub-community .street-pulse-live"
    assert_select ".hub-community .street-pulse-dot"
    assert_select ".hub-community-stats li", count: 3
    assert_select ".hub-community-n", count: 3
    assert_select ".hub-community-label", count: 3
    assert_select ".hub-community-label span", count: 6
    assert_select ".hub-community-label", text: /#{Regexp.escape(I18n.t("hub.players_month_a"))}/
    assert_select ".hub-community-label", text: /#{Regexp.escape(I18n.t("hub.players_month_b"))}/
    assert_select ".hub-community-label", text: /#{Regexp.escape(I18n.t("hub.questions_answered_a"))}/
    assert_select ".hub-community-label", text: /#{Regexp.escape(I18n.t("hub.wards_join_a"))}/
    assert_select ".hub-community-mark-gold[src=?]", "/media/ui/community-people-gold.png"
    assert_select ".hub-community-mark-ink[src=?]", "/media/ui/community-people-ink.png"
    assert_select ".hub-community-mark-gold[src=?]", "/media/ui/community-chat-gold.png"
    assert_select ".hub-community-mark-ink[src=?]", "/media/ui/community-chat-ink.png"
    assert_select ".hub-community-mark-gold[src=?]", "/media/ui/community-temple-gold.png"
    assert_select ".hub-community-mark-ink[src=?]", "/media/ui/community-temple-ink.png"
    assert_select ".hub-community .picto", count: 0
    %w[people chat temple].each do |name|
      %w[gold ink].each do |tone|
        path = Rails.public_path.join("media/ui/community-#{name}-#{tone}.png")
        assert path.file?, "expected #{path}"
      end
    end
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
    assert coronas, "expected current coronas label rule"
    assert_match(/background: none/, coronas)
    refute_match(/border-radius: 999px/, coronas)
    refute_match(/clip-path/, coronas)

    beacon = css[/\.street-map-path\.is-rope \.street-card\.is-pack\.is-current \.street-pack-beacon \{[^}]+\}/m]
    assert beacon, "expected current star pointer rule"
    assert_match(/clip-path: var\(--temple-star4\)/, beacon)
    refute_match(/animation: beacon-bob/, beacon)

    rope = css[/\.street-map-path\.is-rope \.street-map-rope \{[^}]+\}/m]
    assert rope, "expected map path spacer"
    assert_match(/height: 3\.25rem/, rope)
    assert_match(/background: none/, rope)
    refute_match(/repeating-linear-gradient/, rope)

    thread = css[/\.street-map-thread path \{[^}]+\}/m]
    assert thread, "expected gold thread stroke"
    assert_match(/stroke-width: 3/, thread)
    assert_includes css, "--street-map-sway:"
    refute_match(/\.street-map-path\.is-rope \.street-map-track::before \{[^}]*width: 3px/, css)

    lock = css[/\.street-map-path\.is-rope \.street-pack-lock \{[^}]+\}/m]
    assert lock, "expected gold lock seal"
    assert_match(/temple-gold-leaf|--gold-bright/, lock)
    refute_match(/background: none/, lock)
    lock_icon = css[/\.street-map-path\.is-rope \.street-pack-lock \.picto \{[^}]+\}/m]
    assert lock_icon, "expected lock glyph"
    refute_match(/grayscale/, lock_icon)

    chip = css[/\.street-map-path\.is-rope \.street-pack-chip \{[^}]+\}/m]
    assert chip, "expected pack plaque"
    assert_match(/temple-ivory|#fffef9/, chip)

    hub_js = Rails.root.join("app/javascript/controllers/street_hub_controller.js").read
    assert_includes hub_js, "drawPath"
    assert_includes hub_js, "curveThrough"

    path = css[/\.street-map-path\.is-rope \{[^}]+\}/m]
    assert path, "expected scrollable rope path"
    assert_match(/overflow-y: auto/, path)
    assert_match(/--street-map-rope-x:/, path)
    assert_match(/-webkit-mask-image:/, path)
    assert_match(/mask-image:/, path)

    hub = css[/\.street-world:not\(\.street-leaderboard-page\):not\(\.is-profile-gate\):not\(\.street-map-page\) \{[^}]+\}/m]
    assert hub, "expected hub to leave the 100dvh map lock"
    assert_match(/overflow:\s*hidden/, hub)
    feed = css[/\.street-hub-feed \{[^}]+\}/m]
    assert feed, "expected hub feed to scroll under the pinned dock"
    assert_match(/overflow-y: auto/, feed)
    refute_match(/mask-image:/, feed)

    brand = css[/\.street-world > \.street-hub-brand \{[^}]+\}/m]
    assert brand, "expected a solid hub header above the feed"
    assert_match(/z-index:\s*12/, brand)
    assert_match(/min-height:\s*var\(--chrome-head\)/, brand)
    assert_match(/background:\s*var\(--temple-ivory/, brand)
    refute_match(/temple-oculus-rings/, brand)

    titles = css[/\.street-map-path\.is-rope \.street-pack-title \{[^}]+\}/m]
    assert titles, "expected pack title rule"
    assert_match(/font-size: var\(--type-ui\)/, titles)
    assert_match(/line-clamp: 2/, titles)
    refute_match(/white-space: nowrap/, titles)

    league = css[/\.street-world:not\(\.street-leaderboard-page\) \.street-league \{[^}]+\}/m]
    assert league, "expected hub league rule"
    assert_match(/flex-shrink: 0/, league)

    sky = css[/body\.is-street-hub \.sky \{[^}]+\}/m]
    assert sky, "expected faded hall on the hub sky"
    assert_match(/--temple-hall-bg/, sky)
    assert_match(/--temple-ivory/, sky)
    assert_includes css, "--tile-accent: var(--fire)"
    assert_includes css, "--tile-accent: var(--navy)"
    assert_includes css, "--tile-accent: var(--parchment)"
    assert_includes css, "--tile-accent: var(--gold-deep)"

    play = css[/\.street-map-door-play \{[^}]+\}/m]
    assert play, "expected compact gold Jouer jewel on the pack tile"
    assert_match(/clip-path: polygon/, play)
    refute_match(/min-height: 3\./, play)
  end

  test "map door names the open question on the current pack" do
    run = start_street_jugar!
    Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)
    get root_path
    assert_select ".hub-hero-step",
      text: I18n.t("hub.step", n: run.position, total: run.pack.questions.size)
    assert_select ".hub-play.street-map-door-play", text: /#{Regexp.escape(I18n.t("street.world_play"))}/
    assert_select "h2.hub-hero-title", text: QuizDefinition.catalog.find_pack("coronas").copy(:kicker)
    assert_select ".hub-hero-continue", text: I18n.t("hub.continue")
    assert_select ".hub-reward-label", text: I18n.t("hub.reward")
    assert_select ".hub-reward img.hub-reward-chest[src=?]", "/media/temple/reward-chest.png"
    assert_select ".hub-reward-value", text: "+#{QuizDefinition::CURVE_POINTS.drop(1).sum}"
    assert_select ".street-map-door-kicker", text: QuizDefinition.catalog.find_pack("coronas").copy(:kicker)
    assert_select ".hub-play.btn"
    assert_select "a.street-map-door-play"
    assert_select ".street-play-cta", count: 0
    assert_select "turbo-frame#street_pulse[src=?]", street_pulse_path
    assert_select "a.street-pulse[href=?][data-turbo-frame=?]", platform_stats_path, "_top"
    assert_select "a.street-pulse[aria-label=?]", I18n.t("stats.menu")
    assert_select ".street-pulse-month"
    assert_select ".street-pulse-live"
    assert_select ".street-hub-nav" do
      assert_select "a.street-hub-nav-item", count: 5
      assert_select "a[href=?]", root_path, count: 1
      assert_select "a[href=?]", street_map_path, count: 1
      assert_select "a[href=?]", study_program_path, count: 1
      assert_select "a[href=?]", church_path, count: 1
      assert_select "a[href=?]", street_profile_path, count: 1
      assert_select ".picto-meetinghouse", count: 1
      assert_select ".picto-compass", count: 1
      assert_select ".street-hub-word-medallion .picto-scripture-book", count: 1
      assert_select ".picto-church", count: 1
      assert_select ".picto-person", count: 1
      assert_select ".picto-bell", count: 0
    end
    assert_select ".street-hub-nav-item.is-active", text: I18n.t("hub.nav_home")
    assert_select ".hub-shortcuts", count: 0
    assert_select ".hub-shortcut", count: 0
    assert_not_includes response.body, "Boutique"
    assert_not_includes response.body, "Missions"
  end

  test "guest mode hides profile wizard and league" do
    sign_in_congregation
    post street_profile_path, params: { guest: 1 }
    follow_redirect!
    assert_select "#profile_gate", count: 0
    assert_select ".street-league", count: 0
    assert_select ".hub-hero"
    assert_select ".home-menu.is-hud .quiz-hud.is-guest"
    assert_select ".home-menu.is-hud .quiz-hud-cta", text: I18n.t("hub.guest_cta")
    assert_select "a.quiz-hud-who.is-guest[href=?]", root_path(ficha: 1)
    assert_select ".hub-mini", count: 0
    assert_select ".hub-rail.hub-challenge.is-empty"
    assert_select ".hub-online.is-empty", text: /#{Regexp.escape(I18n.t("hub.online_empty"))}/
    assert_select ".hub-online-ranking", text: I18n.t("hub.see_ranking")
    assert_select ".hub-rail-go", text: I18n.t("hub.challenge_them")
    assert_select ".hub-progress .hub-kicker", text: I18n.t("hub.progress")
    assert_select ".hub-progress-meta", text: I18n.t("hub.packs_unlocked", count: 1)
    assert_select ".hub-progress-count", text: "1 / #{QuizDefinition::PACK_COUNT}"
    assert_select ".hub-progress-meter[role=?][aria-valuenow=?][aria-valuemax=?]", "progressbar", "1", QuizDefinition::PACK_COUNT.to_s
    assert_select ".hub-progress-path .hub-progress-mark img", count: 4
    assert_select ".hub-progress-node[aria-current=?] .hub-progress-label", "step", text: QuizDefinition.catalog.packs.first.copy(:title)
    assert_select "#street_world .street-map-path", count: 0
    assert_select ".street-friend-rail", count: 0
    assert_select ".street-hub-nav"
    assert_select "turbo-frame#street_pulse"
    assert_select "a.street-pulse[href=?][data-turbo-frame=?]", platform_stats_path, "_top"
    assert_select "a.street-pulse[aria-label=?]", I18n.t("stats.menu")
    assert_select ".street-play-cta", count: 0
  end

  test "hub live card shows LIVE, weekday, clock boxes, and the program" do
    game_sessions(:david).update!(status: "finished")
    Missionaries::Add.call(night: game_sessions(:elias), name: "Élder Oxxon")
    sign_in_congregation
    post street_profile_path, params: { guest: 1 }
    follow_redirect!
    assert_select ".hub-live[data-hub-live-theme=?]", "dark"
    assert_select ".hub-live.is-celestial-dark[data-hub-live-atmosphere=?]", "glorious"
    assert_select ".hub-live-badge", text: I18n.t("hub.live_chip")
    assert_select ".hub-live-when"
    assert_select ".hub-live-special", text: I18n.t("hub.live_special", theme: game_sessions(:elias).theme_title)
    assert_select ".hub-live-hosts", text: /Élder Oxxon/
    assert_select ".hub-live-clock.is-on"
    assert_select ".hub-live-digit", count: 3
    assert_select ".hub-live-colon", count: 2
    assert_select "a.hub-live-program[href=?]", ward_profile_path("RAMA")
    assert_select "a.hub-live-program .picto-calendar"
    assert_select "a.hub-live-program", text: /#{Regexp.escape(I18n.t("hub.see_program"))}/
    assert_select ".hub-live-join", count: 0
    assert_includes response.body, "/media/nights/noche_live_stage_v2.png"
  end

  test "hub live card keeps its dedicated Dark stage when the hub catalog is Light" do
    Hubs::Backdrop.entries = [
      {
        "id" => "chapel-worship",
        "image" => "church/worship.jpg",
        "tags" => [ "reyes_y_profetas" ],
        "theme" => { "mode" => "light", "atmosphere" => "peaceful", "accent" => "gold" }
      }
    ]
    game_sessions(:david).update!(status: "finished")
    Missionaries::Add.call(night: game_sessions(:elias), name: "Élder Oxxon")
    sign_in_congregation
    post street_profile_path, params: { guest: 1 }
    follow_redirect!
    assert_select ".hub-live[data-hub-live-theme=?]", "dark"
    assert_select ".hub-live.is-celestial-dark[data-hub-live-atmosphere=?]", "glorious"
    assert_includes response.body, "/media/nights/noche_live_stage_v2.png"
    assert_select "a.hub-live-program[href=?]", ward_profile_path("RAMA")
  ensure
    Hubs::Backdrop.reset!
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

  test "camino redirects to the map historial anchor" do
    get street_history_path
    assert_response :success
    get "/camino"
    assert_redirected_to "/mapa#historial"
  end

  test "map page shows the celestial tier path and progression HUD" do
    get street_map_path
    assert_response :success
    assert_select "#street_world.street-map-page"
    assert_select ".mapa-header .mapa-title", text: I18n.t("street.mapa_title")
    assert_select ".mapa-stats-row .mapa-stat-item", count: 4
    assert_select ".mapa-tabs .mapa-tab", count: 4
    assert_select ".mapa-tier[data-tier-key=debutant]"
    assert_select ".mapa-tier[data-tier-key=apprenti]"
    assert_select ".mapa-tier.is-collapsed", count: 2
    assert_select ".mapa-node", count: QuizDefinition.catalog.pack_ids.size
    assert_select ".mapa-node.is-current .mapa-node-beacon"
    assert_select ".mapa-node.is-locked .mapa-node-lock"
    assert_select ".mapa-footer-cta[href=?]", street_leaderboard_path
    assert_select ".home-menu.is-hud .quiz-hud"
    assert_select ".street-world-dock .street-hub-nav-item.is-active[href=?]", street_map_path
    assert_select "a.home-menu-row[href=?]", root_path, text: I18n.t("street.nav_hub")
    assert_select "a.home-menu-row[href=?]", street_map_path, count: 0
  end

  test "unlock param wires packUnlock motion on a locked pack" do
    next_pack = QuizDefinition.catalog.pack_ids.second
    get street_map_path(unlock: next_pack)
    assert_response :success
    assert_select "#pack-#{next_pack}[data-street-motion-sequence-value='packUnlock']"
    assert_select "#pack-#{next_pack}.is-unlocking.is-locked"
    assert_select "#pack-#{next_pack} .street-pack-replay-form", count: 0
    assert_select ".street-pack-play", count: 0
    assert_select ".street-pack-play-wrap", count: 0
  end

  test "unlock param on the current pack does not replay the lock" do
    current = QuizDefinition.catalog.pack_ids.first
    get street_map_path(unlock: current)
    assert_response :success
    assert_select "#pack-#{current}.is-current"
    assert_select "#pack-#{current}.is-unlocking", count: 0
    assert_select "#pack-#{current}.is-locked", count: 0
    assert_select "[data-street-motion-sequence-value='packUnlock']", count: 0
  end

  test "invalid unlock param is ignored" do
    get street_map_path(unlock: "not-a-pack")
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
    assert_select "a.street-pulse[href=?][data-turbo-frame=?]", platform_stats_path, "_top"
    assert_select ".street-play-cta", count: 0
    assert_select ".street-league-all", text: I18n.t("hub.see_ranking")
    assert_select ".home-menu.is-hud .quiz-hud-name", text: pili.given_name
    assert_select ".quiz-hud-rail"
    assert_select ".quiz-hud-level"
    assert_select "a.home-menu-row[href=?]", search_path(cambiar: 1), count: 0
    assert_select ".home-menu-block" do |blocks|
      ward = blocks.find { |block| block.at_css(".home-menu-kicker")&.text&.strip == I18n.t("home.ward_menu") }
      assert ward, "expected a Rama menu section"
      labels = ward.css(".home-menu-label").map { |node| node.text.strip }
      assert_equal [ I18n.t("home.night_code") ], labels
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
    wizard = css[/\.street-wizard \{[^}]+\}/m]
    assert wizard, "expected .street-wizard rule"
    assert_match(/var\(--chrome-head\)/, wizard)
    refute_match(/keyboard-inset-height/, wizard)
    refute_match(/body:has\(#profile_gate\) \{\s*padding-bottom: var\(--keyboard-inset/, css)
    refute_match(/3\.75rem \+ env\(safe-area-inset-top\)/, wizard)
    paper = css[/\.home-paper \{[^}]+\}/m]
    assert paper, "expected .home-paper rule"
    assert_match(/padding: max\(var\(--space-4\), env\(safe-area-inset-top\)\)/, paper)
    world = css[/\.street-world \{[^}]+\}/m]
    assert world, "expected .street-world rule"
    assert_match(/padding: var\(--chrome-head\)/, world)
    clearance = css[/#profile_gate\.street-wizard\.is-ready:has\(\.profile-gate-new\),\n#profile_gate\.street-wizard\.is-ready:has\(\.profile-gate-people\) \{[^}]+\}/m]
    assert clearance, "expected create/device wizard to start below the chrome"
    assert_match(/justify-content:\s*flex-start/, clearance)
    refute_match(/padding-top/, clearance)
    rama = css[/#profile_gate\.street-wizard\.is-ready:has\(#ward_q\) \{[^}]+\}/m]
    assert rama, "expected rama picker to sit under the chrome, not the keyboard"
    assert_match(/justify-content:\s*flex-start/, rama)
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

    get street_map_path
    assert_response :success
    assert_select ".street-world .street-card.is-pack", count: QuizDefinition.catalog.pack_ids.size
    assert_select "#pack-coronas.is-finished .street-pack-replay-form"
    assert_select "#pack-coronas .street-pack-replay", text: I18n.t("street.pack_replay")
    assert_select "#pack-#{QuizDefinition.catalog.pack_ids.second}.is-current .street-pack-replay-form"
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
    assert_select "a.hub-challenge.is-waiting[href=?]", street_challenge_path(duel.token)
    assert_select ".hub-challenge-name.is-hero", text: people(:pili).given_name
    assert_select ".hub-challenge-capsule"
    assert_select ".hub-challenge-vs-disc", text: "VS"
    assert_select ".street-duel-banner", count: 0
    assert_select "form[action=?]", street_challenge_accept_path(duel.token), count: 0
  end

  test "challenger hub shows waiting after a scored challenge" do
    sign_in_congregation
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    follow_redirect!
    street_duels(:pending_challenge).update!(status: "challenger_done", challenger_score: 80)
    get root_path
    assert_select "a.hub-challenge.is-waiting"
    assert_select ".hub-challenge-capsule"
    assert_select ".hub-challenge-face.is-gold img[src*='tortuga']"
    assert_select ".hub-challenge.is-scored", count: 0
    assert_select ".street-duel-banner", count: 0
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
    assert_select "a.hub-challenge.is-waiting[href=?]", street_challenge_path("hub-named-wait")
    assert_select ".hub-challenge-name.is-hero", text: people(:carmen_garcia).given_name
    assert_select ".hub-challenge-face.is-silver img[src*='delfin']"
    assert_select ".hub-challenge-go"
    assert_select ".street-duel-banner", count: 0
    assert_select "a.quiet-link", text: I18n.t("street.duel_inbox_open"), count: 0
  end

  test "player card names the next rank instead of overlaying xp on gold" do
    sign_in_congregation
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    follow_redirect!
    get root_path
    assert_select ".quiz-hud-name", text: pili.given_name
    assert_select ".quiz-hud-rank", text: I18n.t("ranks.guerrero")
    assert_select ".street-xp-caption", count: 0
    assert_select ".street-rank-banner", count: 0
  end

  test "resolved duel on the hub keeps live scores on the tile" do
    sign_in_congregation
    carmen = people(:carmen_garcia)
    street_duels(:pili_vs_carmen).update!(updated_at: Time.current)
    post street_profile_path, params: { person_id: carmen.id, favorite_year: carmen.favorite_year }
    follow_redirect!
    get root_path
    assert_select "a.hub-challenge.is-scored"
    assert_select ".hub-challenge-name", text: people(:pili).given_name
    assert_select ".hub-challenge-sub", text: I18n.t("hub.rival_finished", name: people(:pili).given_name)
    assert_select ".hub-challenge-pts.is-you", text: "90"
    assert_select ".hub-challenge-pts.is-them", text: "82"
    assert_select ".hub-challenge-vs-chip", text: "VS"
    assert_select ".hub-challenge-foot", text: I18n.t("hub.finish_first")
    assert_select ".hub-kicker", text: I18n.t("hub.challenge_now")
    assert_select ".street-card.is-duel.is-compact", count: 0
  end

  test "hub challenge tile CSS covers waiting capsule and scored bar" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read
    assert_includes css, ".hub-challenge-capsule"
    assert_includes css, ".hub-challenge-bar"
    assert_includes css, "--hub-challenge-capsule"
    assert_includes css, ".hub-challenge-vs-chip"
    refute_includes css, ".hub-vs-bar"
  end
end
