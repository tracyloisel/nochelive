require "test_helper"

class StreetHubControllerTest < ActionDispatch::IntegrationTest
  test "home navigation uses place transitions instead of reward sounds" do
    get root_path

    assert_response :success
    assert_select ".hub-play[data-stage-sfx-value]", count: 0

    portal = Rails.root.join("app/javascript/controllers/hub_portal_controller.js").read
    assert_includes portal, 'play?.("celestial_breath", 0.68)'
    refute_includes portal, 'play?.("chest")'
  end

  test "home live countdown sounds only when the event actually starts" do
    countdown = Rails.root.join("app/javascript/controllers/hub_countdown_controller.js").read

    method = countdown[/handleLiveStart\(\) \{[\s\S]*?\n  \}/]
    assert_includes method, 'play?.("round_open", 0.66)'
    assert_equal 1, countdown.scan('play?.("round_open", 0.66)').size
  end

  test "player sees sent invitations and can nudge a waiting friend" do
    duel = street_duels(:pending_challenge)
    ViralEvent.create!(
      name: "invite_share_completed",
      device_digest: "sender-device",
      street_duel: duel,
      person: people(:pili)
    )
    sign_in_congregation
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    follow_redirect!

    assert_select "article.hub-invitations:not(.is-empty)" do
      assert_select ".hub-kicker", text: I18n.t("hub.invitations_title")
      assert_select ".hub-invitation-row.is-sent", count: 1
      assert_select "button.hub-invitation-remind[data-controller=street-share]", text: I18n.t("hub.invitation_remind")
      assert_select "button[data-street-share-duel-token-value=?]", duel.token
      assert_select "button[data-street-share-url-value*=?]", "/desafio/#{duel.token}"
    end
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
    assert_includes css, ".navigation-dock"
    assert_includes css, ".navigation-dock__item"
    assert_includes css, "grid-template-columns: repeat(2, minmax(0, 1fr))"
    assert_includes css, ".street-hub-feed > .hub-hero"
    assert_includes css, ".street-hub-feed > .hub-study"
    assert_includes css, "row-gap: clamp(var(--space-5), 2.6vw, var(--space-7))"
    assert_includes css, "grid-template-columns: repeat(6, minmax(0, 1fr))"
    assert_includes css, ".hub-panel-row > .hub-invitations"
    assert_includes css, "grid-column: span 3"
    assert_includes css, ".hub-panel-row > .hub-videos"
    assert_includes css, "grid-row: 3"
    assert_includes css, "grid-template-columns: var(--hub-grid-gutter) repeat(12, minmax(0, 1fr)) var(--hub-grid-gutter)"
    assert_includes css, "grid-column: 2 / 14"
    assert_includes css, "grid-column: 2 / span 8"
    assert_includes css, "grid-column: 10 / span 4"
  end

  test "hub artwork theme propagates to the shared HUD chrome" do
    get root_path

    assert_response :success
    theme = css_select("#street_world").first["data-hub-theme"]
    assert_includes %w[light dark], theme
    assert_select "body.is-game-hub-page.is-celestial-#{theme}"
    assert_select "body.is-game-hub-page > .home-menu.is-hud .quiz-hud"
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
    assert_select ".hub-online-stats[aria-label=?]", I18n.t("hub.online_meta", count: 208, crowns: 208) do
      assert_select ".picto-crown", count: 1
    end
    assert_select ".hub-online-presence .street-live-dot", count: 2
    assert_select ".hub-online-name-line > .hub-online-name + .hub-online-presence", count: 2
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
    assert_includes css, ".street-world.is-game-hub .hub-online-name-line"
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
    create_street_profile!
    assert_select "a.hub-community[href=?]", platform_stats_path do
      assert_select ".hub-kicker", text: I18n.t("hub.community")
      assert_select ".street-pulse"
    end
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
    assert_select ".street-pulse"
    assert_select ".street-pulse-month"
    assert_select ".street-pulse-live"
    assert_select ".navigation-dock" do
      assert_select "a.navigation-dock__item", count: 5
      assert_select "a[href=?]", root_path, count: 1
      assert_select "a[href=?]", street_map_path, count: 1
      assert_select "a[href=?]", study_program_path, count: 1
      assert_select "a[href=?]", church_path, count: 1
      assert_select "a[href=?]", street_profile_path(edit: 1), count: 1
      assert_select ".picto-meetinghouse", count: 1
      assert_select ".picto-compass", count: 1
      assert_select ".navigation-dock__item[href='/parole'] > .picto-scripture-book", count: 1
      assert_select ".street-hub-word-medallion", count: 0
      assert_select ".picto-church", count: 1
      assert_select ".picto-person", count: 1
      assert_select ".picto-bell", count: 0
    end
    assert_select ".navigation-dock__item.is-active", text: I18n.t("hub.nav_home")
    assert_select ".hub-shortcuts", count: 0
    assert_select ".hub-shortcut", count: 0
    assert_not_includes response.body, "Boutique"
    assert_not_includes response.body, "Missions"
  end

  test "visitor mode shows the hub without player-only league data" do
    get root_path
    assert_select "#profile_gate", count: 0
    assert_select ".street-league", count: 0
    assert_select ".hub-hero"
    assert_select ".home-menu.is-hud .quiz-hud.is-guest"
    assert_select ".home-menu.is-hud .quiz-hud-cta-long", text: I18n.t("hub.guest_cta")
    assert_select "a.quiz-hud-who.is-guest[href=?]", street_profile_path(fresh: 1)
    assert_select ".hub-mini", count: 0
    assert_select "a.hub-challenge.is-ward-required[href=?]", search_path(cambiar: 1)
    assert_select ".hub-challenge-empty-hint", text: I18n.t("hub.challenge_pick_ward")
    assert_select ".hub-online-ward-required", text: /#{Regexp.escape(I18n.t("hub.online_pick_ward"))}/
    assert_select ".hub-online-ranking[href=?]", search_path(cambiar: 1), text: I18n.t("hub.pick_ward_action")
    assert_select ".hub-progress .hub-kicker", text: I18n.t("hub.progress")
    assert_select ".hub-progress-meta", text: I18n.t("hub.packs_unlocked", count: 1)
    assert_select ".hub-progress-count", text: "1 / #{QuizDefinition::PACK_COUNT}"
    assert_select ".hub-progress-meter[role=?][aria-valuenow=?][aria-valuemax=?]", "progressbar", "1", QuizDefinition::PACK_COUNT.to_s
    if StudyProgram.order(year: :desc).first
      assert_select "a.hub-progress-word[href=?]", study_program_path do
        assert_select ".hub-progress-word-copy strong", text: I18n.t("study.title")
      end
    end
    assert_select ".hub-progress-path .hub-progress-mark img", count: 4
    assert_select ".hub-progress-path .hub-progress-status", count: 4
    assert_select "#street_world .street-map-path", count: 0
    assert_select ".street-friend-rail", count: 0
    assert_select ".navigation-dock"
    assert_select "turbo-frame#street_pulse"
    assert_select ".street-pulse"
    assert_select ".street-play-cta", count: 0
  end

  test "hub live card shows LIVE, weekday, clock boxes, and the program" do
    game_sessions(:david).update!(status: "finished")
    Missionaries::Add.call(night: game_sessions(:elias), name: "Élder Oxxon")
    sign_in_congregation
    create_street_profile!
    assert_select ".hub-live[data-hub-live-theme][data-hub-live-atmosphere]"
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

  test "hub live card follows Celestial Light with its dedicated stage" do
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
    create_street_profile!
    assert_select ".hub-live[data-hub-live-theme=?]", "light"
    assert_select ".hub-live.is-celestial-light[data-hub-live-atmosphere=?]", "peaceful"
    assert_includes response.body, "/media/nights/noche_live_stage_v2.png"
    assert_select "a.hub-live-program[href=?]", ward_profile_path("RAMA")
  ensure
    Hubs::Backdrop.reset!
  end

  test "legacy camino paths redirect to the map historial anchor" do
    get "/camino"
    assert_redirected_to "/mapa#historial"

    get "/camino/historial"
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
    assert_select "body > .home-menu.is-hud .quiz-hud"
    assert_select "body > .navigation-dock .navigation-dock__item.is-active[href=?]", street_map_path
    assert_select "#street_world .home-menu", count: 0
    assert_select "#street_world .navigation-dock", count: 0
    assert_select "a.home-menu-row[href=?]", root_path, text: I18n.t("street.nav_hub")
    assert_select "a.home-menu-row[href=?]", street_map_path, count: 0

    css = Rails.root.join("app/assets/stylesheets/application.css").read
    map_body = css[/body\.is-street-map-page \{[^}]+\}/m]
    refute_includes map_body, "--hud-inset"
    refute_includes map_body, "--navigation-dock-width"
    assert_includes css, "body.is-street-map-page .sky { background: none; }"
    assert_match(/\.home-menu\.is-hud \{[^}]*position: fixed;[^}]*left: env\(safe-area-inset-left\);[^}]*right: env\(safe-area-inset-right\);[^}]*max-width: none;[^}]*transform: none;/m, css)
    assert_match(/\.navigation-dock \{[^}]*position: fixed;[^}]*left: 0;[^}]*right: 0;[^}]*width: auto;/m, css)
    assert_match(/\.street-world\.street-map-page \{[^}]*padding: calc\(6rem \+ env\(safe-area-inset-top\)\)/m, css)
    refute_includes css, ".street-map-page > .home-menu"
  end

  test "unlock param wires packUnlock motion on a locked pack" do
    next_pack = QuizDefinition.catalog.pack_ids.second
    get street_map_path(unlock: next_pack)
    assert_response :success
    assert_select "#pack-#{next_pack}[data-street-motion-sequence-value='packUnlock']"
    assert_select "#pack-#{next_pack}.is-unlocking.is-locked"
    assert_select "#pack-#{next_pack} .mapa-node-hit", count: 0
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
    assert_select ".street-pulse"
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

  test "rank_up param plays level_up once from stage_sfx" do
    get root_path(rank_up: 1)
    assert_response :success
    assert_select "#street_world[data-stage-sfx-value=level_up]"
    assert_select "#street_world[data-stage-sfx-token-value^='hub:rank_up:']"
    assert_select "[data-street-hub-rank-up-value]", count: 0
  end

  test "finished pack is replayable without a gold node CTA" do
    sign_in_congregation
    create_street_profile!
    post street_pack_start_path("coronas")
    follow_redirect!
    run = QuizRun.open_runs.order(:id).last
    run.update!(position: 10)
    Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)
    Quizzes::Complete.call(run: run.reload)

    get street_map_path
    assert_response :success
    assert_select ".street-world .mapa-node", count: QuizDefinition.catalog.pack_ids.size
    assert_select "#pack-coronas.is-finished form[action=?]", street_pack_start_path("coronas")
    assert_select "#pack-coronas.is-finished button.mapa-node-hit"
    assert_select "#pack-#{QuizDefinition.catalog.pack_ids.second}.is-current form[action=?]",
      street_pack_start_path(QuizDefinition.catalog.pack_ids.second)
    assert_select ".mapa-node.is-locked .mapa-node-hit", count: 0

    post street_pack_start_path("coronas")
    follow_redirect!
    assert_select "#street_quiz"
    replay = QuizRun.open_runs.order(:id).last
    assert replay
    assert_equal "coronas", replay.pack_id
    assert_not_equal run.id, replay.id
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
    assert_select ".hub-challenge-status.is-waiting"
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
    assert_select ".hub-challenge-status.is-waiting"
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
    assert_select ".quiz-hud-rank > span:first-child", text: I18n.t("ranks.guerrero")
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
    assert_includes css, "a.hub-challenge.is-waiting .hub-challenge-waiting-body"
    assert_includes css, "a.hub-challenge.is-waiting .hub-challenge-status"
    refute_includes css, ".hub-vs-bar"
  end
end
