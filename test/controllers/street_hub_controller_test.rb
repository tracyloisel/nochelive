require "test_helper"

class StreetHubControllerTest < ActionDispatch::IntegrationTest
  test "home offers the installable app as the first temporary hub tile" do
    get root_path

    assert_response :success
    assert_select ".street-hub-feed > button.hub-panel.hub-install[hidden][aria-label=?]", I18n.t("pwa.install") do
      assert_select "[data-pwa-install-target~='action'][data-pwa-install-target~='tile']"
      assert_select "[data-action='pwa-install#install']"
      assert_select "img[src='/apple-touch-icon.png']"
      assert_select ".hub-kicker", text: I18n.t("pwa.kicker")
      assert_select ".hub-install-copy strong", text: I18n.t("pwa.banner_title")
      assert_select "#hub_install_hint", text: I18n.t("pwa.banner_hint")
      assert_select ".hub-install-cta", text: /#{Regexp.escape(I18n.t("pwa.install"))}/
      assert_select ".btn-gold", count: 0
    end
    assert_select ".street-hub-feed > .hub-install + .hub-hero", count: 1

    assert_select "dialog.pwa-install-dialog[aria-labelledby='pwa_install_title'][aria-describedby='pwa_install_lede']" do
      assert_select "template[data-pwa-install-target='guideTemplate']", count: 1
      assert_select ".pwa-install-sheet[data-pwa-install-target~='sheet'][tabindex='-1']"
      assert_select ".pwa-install-apex .picto-star4"
      assert_select ".pwa-install-emblem img[src='/apple-touch-icon.png']"
      assert_select "#pwa_install_title", text: I18n.t("pwa.ios_title")
      assert_select "#pwa_install_lede", text: I18n.t("pwa.banner_hint")
      assert_select ".pwa-install-steps li", count: 4
      assert_select "picture.pwa-install-step-art-picture", count: 4 do
        assert_select "source[type='image/avif'][srcset*='64w'][srcset*='512w']", count: 4
        assert_select ".pwa-install-step-art[loading='lazy'][decoding='async']", count: 4
      end
      assert_select "button.pwa-install-done", text: /#{Regexp.escape(I18n.t("pwa.done"))}/
      assert_select ".pwa-install-done .picto-check"
    end

    controller = Rails.root.join("app/javascript/controllers/pwa_install_controller.js").read
    assert_includes controller, "this.hasTileTarget"
    assert_includes controller, "window.NocheInstallPrompt"
    assert_includes controller, "this.isStandalone()"
    assert_includes controller, "this.hideInstallUi()"
    assert_includes controller, 'import("features/pwa/install_guide")'
    guide = Rails.root.join("app/javascript/features/pwa/install_guide.js").read
    assert_includes guide, "mountInstallGuide"
    assert_includes guide, "resetInstallGuide"
    assert_includes guide, "content.cloneNode(true)"
    assert_includes guide, "controller.dialogTarget.scrollTop = 0"
    assert_includes guide, "controller.sheetTarget.focus({ preventScroll: true })"
  end

  test "home keeps non-critical code fonts audio and images off the render path" do
    get root_path, headers: { "HTTP_ACCEPT" => "text/html,image/webp" }

    assert_response :success
    controller_preloads = css_select("link[rel='modulepreload']").filter_map { |node| node["href"] }
      .grep(%r{/controllers/|/haptics})
    assert_empty controller_preloads
    assert_select "link[href*='fonts.googleapis.com'][rel='preload'][as='style'][data-noche-font-preload]", count: 1
    assert_select "audio#noche_sfx_gate[preload='none']", count: 1
    assert_select "#street_world[style*='.webp']", count: 1
    assert_select ".hub-slide.is-current picture.hub-slide-still-picture", count: 1 do
      assert_select "source[type='image/avif'][srcset*='390w']", count: 1
      assert_select "source[type='image/webp']", count: 1
      assert_select "img.hub-slide-still[fetchpriority='high'][decoding='async']", count: 1
    end
    assert_select ".hub-reward picture source[type='image/webp']", minimum: 1

    imports = Rails.root.join("app/javascript/controllers/index.js").read
    assert_includes imports, "lazyLoadControllersFrom"
    refute_includes imports, "eagerLoadControllersFrom"
  end

  test "home navigation uses place transitions instead of reward sounds" do
    get root_path

    assert_response :success
    assert_select ".hub-play[data-stage-sfx-value]", count: 0

    portal = Rails.root.join("app/javascript/controllers/hub_portal_controller.js").read
    assert_includes portal, 'audioLoader.play("celestial_breath", 0.68)'
    refute_includes portal, 'audioLoader.play("chest")'
  end

  test "home live countdown sounds only when the event actually starts" do
    countdown = Rails.root.join("app/javascript/controllers/hub_countdown_controller.js").read

    method = countdown[/handleLiveStart\(\) \{[\s\S]*?\n  \}/]
    assert_includes method, 'audioLoader.play("round_open", 0.66)'
    assert_equal 1, countdown.scan('audioLoader.play("round_open", 0.66)').size
  end

  test "menu footer lists the three requested legal destinations" do
    get root_path
    assert_response :success
    assert_select ".hub-menu-legal" do
      assert_select "a[href=?]", about_path, text: I18n.t("hub_menu.about_us")
      assert_select "a[href=?]", legal_path, text: I18n.t("hub_menu.legal")
      assert_select "a[href=?]", privacy_path, text: I18n.t("hub_menu.privacy")
    end
  end

  test "hub five-tab dock is in the game-hub CSS" do
    shell = Rails.root.join("app/assets/stylesheets/application.css").read
    css = Rails.root.join("app/assets/stylesheets/surfaces/hub.css").read
    assert_includes shell, ".navigation-dock"
    assert_includes shell, ".navigation-dock__item"
    assert_includes css, "grid-template-columns: repeat(2, minmax(0, 1fr))"
    assert_includes css, ".street-hub-feed > .hub-hero"
    assert_includes css, ".street-hub-feed > .hub-study"
    assert_includes css, "row-gap: clamp(var(--space-5), 2.6vw, var(--space-7))"
    assert_includes css, "grid-template-columns: repeat(6, minmax(0, 1fr))"
    assert_includes Rails.root.join("app/assets/stylesheets/surfaces/hub.css").read, ".hub-duel-campus"
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
    assert_select "body.is-game-hub-page > .home-menu.is-hud[data-hud-theme='celestial-#{theme}'] .quiz-hud[data-hud-theme='celestial-#{theme}']"
  end

  test "hub artwork is not covered by a global darkening veil" do
    css = Rails.root.join("app/assets/stylesheets/surfaces/hub.css").read

    refute_match(/\.street-world\.is-game-hub::before\s*\{/, css)
    refute_includes css, "--overlay-soft"
    refute_includes css, "--overlay-strong"
  end

  test "celestial light tiles use local contrast treatments" do
    css = Rails.root.join("app/assets/stylesheets/surfaces/hub.css").read

    assert_includes css, '[data-hub-theme="light"] .hub-progress-path .hub-progress-mark'
    assert_includes css, '.hub-light-tile--hero .hub-slide::after'
    assert_includes css, '.hub-light-tile--videos .hub-videos-scrim'
    assert_includes css, '.hub-light-tile--community .hub-community-art img'
    assert_includes css, '.hub-light-tile--campus .hub-duel-campus-scrim'
    assert_includes css, '.hub-light-tile--progress .hub-progress-art-scrim'
  end

  test "celestial light tiles share a semantic typography palette" do
    css = Rails.root.join("app/assets/stylesheets/surfaces/hub.css").read

    %w[primary secondary muted].each do |role|
      assert_includes css, "--hub-light-type-on-paper-#{role}:"
    end
    %w[hero study live campus online progress videos community install].each do |tile|
      assert_includes css, ".hub-light-tile--#{tile}"
    end
    assert_includes css, ".hub-light-tile--online .hub-kicker { color: var(--hub-light-type-on-paper-primary); }"
    assert_includes css, ".hub-light-tile--community .hub-community-label { color: var(--hub-light-type-on-paper-secondary); }"
  end

  test "celestial light gives every hub tile an authored composition" do
    Hubs::Backdrop.entries = [
      {
        "id" => "chapel-worship",
        "image" => "church/worship.jpg",
        "tags" => [ "reyes_y_profetas" ],
        "theme" => { "mode" => "light", "atmosphere" => "peaceful", "accent" => "gold" }
      }
    ]

    get root_path

    assert_response :success
    %w[hero live campus online progress videos community install].each do |tile|
      assert_select ".hub-light-tile--#{tile}", count: 1
    end
    css = Rails.root.join("app/assets/stylesheets/surfaces/hub.css").read
    assert_includes css, ".hub-light-tile--study"
    %w[campus-scriptures-v2 friends-online-v2 progress-path-v2 video-sanctuary-v2 community-gathering-v2 install-portal-v2].each do |art|
      assert_select "img[src*='/media/generated/catalog/hub/light/#{art}/']", count: 1
    end
    assert Rails.root.join("media/masters/media/hub/light/study-refuge-v2.png").file?
    assert_select "img[src*='/media/generated/catalog/hub/light/hero-gateway-v2/']", minimum: 1
    assert_select ".hub-live[style*='/media/generated/catalog/hub/light/live-stage-v2/']", count: 1
  ensure
    Hubs::Backdrop.reset!
  end

  test "online tile shows two real friends ranks crowns and leaderboard CTA" do
    mark_person_online(people(:carmen_garcia))
    mark_person_online(people(:carmen_lopez))
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
    css = Rails.root.join("app/assets/stylesheets/application.css").read + Rails.root.join("app/assets/stylesheets/surfaces/hub.css").read
    tile = css[/\.street-world\.is-game-hub \.hub-online \{[^}]+\}/m]
    assert tile, "expected isolated online tile rule"
    refute_match(%r{grid-column: 1 / -1}, tile)
    assert_includes css, "--hub-online-live: #31bd65"
    assert_includes css, '.street-world.is-game-hub[data-hub-theme="light"] .hub-light-tile--online'
    assert_includes css, '.street-world.is-game-hub[data-hub-theme="dark"] .hub-online'
    assert_includes css, ".street-world.is-game-hub .hub-online-presence .street-live-dot"
    assert_includes css, ".street-world.is-game-hub .hub-online-name-line"
    assert_includes css, ".street-world.is-game-hub .hub-online-ranking"
    assert_match(/\.street-world\.is-game-hub \.hub-online \{[^}]+align-self: start/m, css)
    assert_match(/\.street-world\.is-game-hub \.hub-online-head \{[^}]+flex-direction: row/m, css)
    assert_match(/\.street-world\.is-game-hub \.hub-online-list \{[^}]+flex: none/m, css)
  end

  test "community tile CSS uses readable stat rows with two-line labels in Light and Dark" do
    css = Rails.root.join("app/assets/stylesheets/surfaces/hub.css").read
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
    assert_includes css, ".street-world.is-game-hub[data-hub-theme=\"light\"] .hub-light-tile--community .hub-community-stats li + li"
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
    assert_select ".hub-community-mark-gold[src*=?]", "/media/generated/catalog/ui/community-people-gold/"
    assert_select ".hub-community-mark-ink[src*=?]", "/media/generated/catalog/ui/community-people-ink/"
    assert_select ".hub-community-mark-gold[src*=?]", "/media/generated/catalog/ui/community-chat-gold/"
    assert_select ".hub-community-mark-ink[src*=?]", "/media/generated/catalog/ui/community-chat-ink/"
    assert_select ".hub-community-mark-gold[src*=?]", "/media/generated/catalog/ui/community-temple-gold/"
    assert_select ".hub-community-mark-ink[src*=?]", "/media/generated/catalog/ui/community-temple-ink/"
    assert_select ".hub-community .picto", count: 0
    %w[people chat temple].each do |name|
      %w[gold ink].each do |tone|
        path = Rails.root.join("media/masters/media/ui/community-#{name}-#{tone}.png")
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
    assert_includes css, ".is-drawer-close"
  end

  test "hub chrome matches temple mockup" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read + Rails.root.join("app/assets/stylesheets/surfaces/hub.css").read
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

    league = css[/\.street-world:not\(\.street-leaderboard-page\) \.street-league \{[^}]+\}/m]
    assert league, "expected hub league rule"
    assert_match(/flex-shrink: 0/, league)

    sky = css[/body\.is-street-hub \.sky \{[^}]+\}/m]
    assert sky, "expected faded hall on the hub sky"
    assert_match(/--temple-ivory/, sky)
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
    assert_select ".hub-reward img.hub-reward-chest[src*=?]", "/media/generated/catalog/temple/reward-chest/"
    assert_select ".hub-reward-value", text: "+84"
    assert_select ".street-map-door-kicker", text: QuizDefinition.catalog.find_pack("coronas").copy(:kicker)
    assert_select ".hub-play.btn"
    assert_select "a.street-map-door-play"
    assert_select ".street-play-cta", count: 0
    assert_select "turbo-frame#street_pulse:not([src])"
    assert_select "turbo-cable-stream-source", minimum: 1
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
    assert_select "a.hub-duel-campus[href=?][data-controller~='hub-campus']", street_challenges_path do
      assert_select ".hub-duel-campus-heading", text: /#{Regexp.escape(I18n.t("duel_campus.hub.title"))}/
      assert_select ".hub-duel-campus-empty", text: I18n.t("duel_campus.hub.empty")
      assert_select ".hub-duel-campus-stats", count: 0
      assert_select ".hub-duel-campus-cta", text: I18n.t("duel_campus.hub.cta")
      assert_select "> b", count: 0
    end
    assert_select ".hub-online-ward-required", text: /#{Regexp.escape(I18n.t("hub.online_pick_ward"))}/
    assert_select ".hub-online-ranking[href=?]", search_path(cambiar: 1), text: I18n.t("hub.pick_ward_action")
    assert_select ".hub-online.is-illustrated .hub-online-art picture", count: 1 do
      assert_select "source[type='image/avif'][srcset*='390w']", count: 1
      assert_select "source[type='image/webp']", count: 1
      assert_select "img[loading='lazy'][decoding='async']", count: 1
    end
    assert_select ".hub-online-scrim", count: 1
    assert_select ".hub-live.is-ward_missing.is-still[style*='/media/generated/catalog/nights/noche_live_stage_v2/']", count: 1
    assert_select ".hub-progress .hub-kicker", text: I18n.t("hub.progress")
    assert_select "a.hub-progress-map-link[href=?]", street_map_path do
      assert_select ".hub-progress-map-action", text: I18n.t("street.world_map_open")
      assert_select ".picto-compass", count: 1
    end
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
    assert_select ".street-friend-rail", count: 0
    assert_select ".navigation-dock"
    assert_select "turbo-frame#street_pulse"
    assert_select ".street-pulse"
    assert_select ".street-play-cta", count: 0
  end

  test "Campus hub tile explains each large number and reveals it only in view" do
    sign_in_congregation
    person = people(:carmen_garcia)
    post street_profile_path, params: { person_id: person.id, favorite_year: person.favorite_year }
    follow_redirect! if response.redirect?
    campus = Quizzes::DuelCampus.call(person:)

    assert campus.any?
    assert_select "a.hub-duel-campus[data-action='click->hub-campus#depart']" do
      assert_select ".hub-duel-campus-stats[role='list'][aria-label=?]", I18n.t("duel_campus.hub.summary") do
        assert_select ".hub-duel-campus-stat[role='listitem']", count: 3
        %i[incoming active results].each do |key|
          count = campus.counts.public_send(key)
          assert_select ".hub-duel-campus-stat.is-#{key}" do
            assert_select "b[data-hub-campus-target~='number'][data-value=?]", count.to_s, text: count.to_s
            assert_select "> span:last-child", text: I18n.t("duel_campus.hub.#{key}", count:)
          end
        end
      end
      assert_select ".hub-duel-campus-cta .picto-arrow", count: 1
    end

    controller = Rails.root.join("app/javascript/controllers/hub_campus_controller.js").read
    assert_includes controller, "IntersectionObserver"
    assert_includes controller, "prefers-reduced-motion: reduce"
    assert_includes controller, 'motionDirector.run("list-enter"'
    assert_includes controller, "motionDirector.count(0, target"
  end

  test "Campus hub tile inherits the backdrop Celestial Light and Dark theme tokens" do
    css = Rails.root.join("app/assets/stylesheets/surfaces/hub.css").read

    assert_includes css, '.street-world.is-game-hub[data-hub-theme="light"] .hub-duel-campus'
    assert_includes css, '.street-world.is-game-hub[data-hub-theme="dark"] .hub-duel-campus'
    assert_includes css, "var(--surface-primary)"
    assert_includes css, "var(--surface-glass)"
    assert_includes css, "var(--text-primary)"
    assert_includes css, "var(--border-gold)"
    assert_includes css, "var(--shadow-card)"
    assert_includes css, "prefers-reduced-motion: reduce"
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
    assert_select ".hub-live[style*='/media/generated/']", count: 1
  end

  test "playing hub live card presents Entrer as the primary game command" do
    sign_in_congregation

    get root_path

    assert_response :success
    assert_select ".hub-live.is-playing a.hub-live-join[href=?]", night_name_path(game_sessions(:david).code) do
      assert_select ".hub-live-join-label", text: I18n.t("hub.live_join")
      assert_select ".hub-live-join-mark[aria-hidden=true] .picto-arrow", count: 1
    end
    assert_select ".hub-live.is-playing a.hub-live-join.btn-gold", count: 0
    assert_select ".hub-live.is-playing a.hub-live-program", count: 1

    css = Rails.root.join("app/assets/stylesheets/surfaces/hub.css").read
    command = css[/\.hub-live-join\s*\{[^}]+\}/m]
    assert command
    assert_match(/min-height:\s*3\.35rem/, command)
    assert_match(/clip-path:\s*polygon\(/, command)
    assert_match(/backdrop-filter:\s*blur\(16px\)/, command)
    refute_match(/background:\s*var\(--button-primary\)/, command)
    assert_includes css, "--hub-live-command-glass:"
    assert_includes css, "@keyframes hub-live-command-glint"
    assert_includes css, ".hub-live.is-playing .hub-live-join::after { animation: none; }"
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
    assert_select ".hub-live[style*='/media/generated/']", count: 1
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
    assert_select "link[href*='pages/street_map'][data-turbo-track='dynamic']", count: 1
    assert_select "#street_world.street-map-page"
    assert_select ".mapa-header .mapa-title", text: I18n.t("street.mapa_title")
    assert_select ".mapa-mission"
    assert_select ".mapa-mission-progress[role=progressbar]"
    assert_select ".mapa-continue", text: I18n.t("hub.continue")
    assert_select ".mapa-stats-row", count: 0
    assert_select ".mapa-tabs .mapa-tab", count: 4
    assert_select ".mapa-tabs .mapa-tab[aria-selected=true]", count: 1
    assert_select ".mapa-tier[data-tier-key=debutant]"
    assert_select ".mapa-tier[data-tier-key=apprenti]"
    assert_select ".mapa-tier.is-collapsed", count: 2
    assert_select ".mapa-node", count: QuizDefinition.catalog.pack_ids.size
    assert_select ".mapa-node.is-current .mapa-node-beacon"
    assert_select ".mapa-node.is-current[aria-current=step]"
    assert_select ".mapa-node.is-locked[data-action*='click->hub-map#tapNode'] .mapa-node-lock"
    assert_select ".mapa-footer-cta[href=?]", street_leaderboard_path
    assert_select "body > .home-menu.is-hud .quiz-hud"
    assert_select "body > .navigation-dock .navigation-dock__item.is-active[href=?]", street_map_path
    assert_select "#street_world .home-menu", count: 0
    assert_select "#street_world .navigation-dock", count: 0
    assert_select "a.home-menu-invite[href=?]", street_challenges_path(anchor: "inviter"), text: /#{Regexp.escape(I18n.t("hub_menu.invite_friend"))}/
    assert_select "a.home-menu-row[href=?]", street_leaderboard_path, text: I18n.t("hub_menu.leaderboard")
    assert_select "a.home-menu-row[href=?]", study_program_path, text: /#{Regexp.escape(I18n.t("study.title"))}/
    assert_select "a.home-menu-row[href=?]", street_map_path, count: 0

    page_css = Rails.root.join("app/assets/stylesheets/pages/street_map.css").read
    css = Rails.root.join("app/assets/stylesheets/application.css").read + Rails.root.join("app/assets/stylesheets/surfaces/hub.css").read + page_css
    assert_includes page_css, ".mapa-mission {"
    assert_includes page_css, ".mapa-tabs {"
    assert_includes page_css, ".mapa-node-circle {"
    map_body = css[/body\.is-street-map-page \{[^}]+\}/m]
    refute_includes map_body, "--hud-inset"
    refute_includes map_body, "--navigation-dock-width"
    assert_includes css, "body.is-street-map-page .sky { background: none; }"
    assert_match(/\.home-menu\.is-hud \{[^}]*position: fixed;[^}]*left: env\(safe-area-inset-left\);[^}]*right: env\(safe-area-inset-right\);[^}]*max-width: none;[^}]*transform: none;/m, css)
    assert_match(/\.navigation-dock \{[^}]*position: fixed;[^}]*left: 0;[^}]*right: 0;[^}]*width: auto;/m, css)
    assert_match(/\.street-world\.street-map-page \{[^}]*padding: calc\(6rem \+ env\(safe-area-inset-top\)\)/m, css)
    refute_includes css, "body.is-street-hub:has(.home-menu.is-hud) .street-map-page"
    refute_includes css, ".street-map-page > .home-menu"
  end

  test "map page stylesheet stays off the home render path" do
    get root_path

    assert_response :success
    assert_select "link[href*='pages/street_map']", count: 0
    assert Rails.root.join("app/assets/stylesheets/pages/street_map.css").file?
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
    assert_select ".home-menu-kicker", text: I18n.t("hub_menu.space")
    assert_select "a.home-menu-row[href=?]", study_program_path, text: /#{Regexp.escape(I18n.t("study.title"))}/
    assert_select "a.home-menu-row[href=?]", ward_profile_path("RAMA"), text: /#{Regexp.escape(I18n.t("hub_menu.my_ward"))}/
    assert_select "a.home-menu-invite[href=?]", street_challenges_path(anchor: "inviter"), text: /#{Regexp.escape(I18n.t("hub_menu.invite_friend"))}/
    assert_select "a.home-menu-row[href=?]", street_leaderboard_path, text: I18n.t("hub_menu.leaderboard")
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
end
