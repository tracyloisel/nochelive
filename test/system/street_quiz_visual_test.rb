require "application_system_test_case"

class StreetQuizVisualTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/street-shots")
  TEMPLE_SHOT_DIR = Rails.root.join("tmp/street-shots/temple-themed")

  test "liga lives in the celestial light court with thousand player windows" do
    seed_liga_window_rows!(total: 1_000)
    sign_in_fixture_person_direct!(people(:pili))
    page.driver.browser.manage.add_cookie(name: Locale::COOKIE.to_s, value: "fr", path: "/")

    [ [ 390, 844 ], [ 768, 1024 ], [ 1440, 900 ] ].each_with_index do |(width, height), index|
      set_quiz_viewport(width, height)
      visit street_leaderboard_path

      assert_no_horizontal_layout_overflow
      assert_selector "body.is-celestial-light"
      assert_selector ".street-leaderboard-page.liga-court[data-controller~='liga-board']"
      assert_selector "h1", text: I18n.t("street.leaderboard_court_title", locale: :fr)
      assert_selector ".liga-court-heading", text: /1[,  ]000 joueurs/
      assert_selector ".liga-court-podium-place", count: 3
      assert_selector ".liga-rivalry"
      assert_selector ".liga-around .liga-court-row", count: 3
      assert_selector ".liga-rivalry-cta"
      assert_selector ".liga-challenge-strip"
      assert_no_selector ".liga-full-panel"
      assert_no_selector ".street-liga-you-bar"
      assert_no_selector "select"
      assert_layout_chrome_full_width
      assert_liga_touch_targets!
      if index.zero?
        assert_selector ".street-leaderboard-page.is-liga-enter"
        assert_equal "liga-podium-side-in", page.evaluate_script("getComputedStyle(document.querySelector('.liga-court-podium-place.is-place-2')).animationName")
        assert_equal "liga-podium-champion-in", page.evaluate_script("getComputedStyle(document.querySelector('.liga-court-podium-place.is-place-1')).animationName")
        assert_equal "liga-panel-rise", page.evaluate_script("getComputedStyle(document.querySelector('.liga-rivalry')).animationName")
      else
        assert_no_selector ".street-leaderboard-page.is-liga-enter"
      end
      page.execute_script("document.querySelector('#street_world')?.classList.remove('is-liga-enter')")
      shot("liga-celestial-light-#{width}x#{height}")
      assert_empty page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
    end

    set_quiz_viewport(390, 844)
    visit street_leaderboard_path(view: "full", scope: "stake")
    assert_selector ".liga-full-panel"
    assert_selector ".liga-court-list.is-full .liga-court-row", count: 100
    assert_selector ".liga-cursor-link.is-next", text: /#{Regexp.escape(I18n.t("street.leaderboard_next_group", count: 100, locale: :fr))}/i
    assert_selector ".street-liga-you-bar", visible: :all
    assert_no_horizontal_layout_overflow
    shot("liga-celestial-light-full-390x844")

    fill_in I18n.t("street.leaderboard_search", locale: :fr), with: @liga_last_name
    assert_selector ".liga-court-list.is-full .liga-court-row", count: 1
    assert_selector ".liga-court-row-person", text: @liga_last_name
    assert_selector ".liga-full-count", text: /1 sur 1[,  ]000 joueurs/
    assert_empty page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }

    page.driver.browser.execute_cdp(
      "Emulation.setEmulatedMedia",
      features: [ { name: "prefers-reduced-motion", value: "reduce" } ]
    )
    visit street_leaderboard_path
    assert_no_selector ".street-leaderboard-page.is-liga-enter"
    assert_equal "none", page.evaluate_script("getComputedStyle(document.querySelector('.liga-court-heading')).animationName")
    assert_equal "none", page.evaluate_script("getComputedStyle(document.querySelector('.liga-court-podium-place.is-place-1')).animationName")
  ensure
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: []) rescue nil
  end

  test "layout chrome keeps one viewport contract across destinations" do
    set_quiz_viewport(804, 1_100)
    sign_in_fixture_person_direct!(people(:pili))

    [
      [ root_path, nil, "hub" ],
      [ street_map_path, "celestial-light", "adventure" ],
      [ street_leaderboard_path, "celestial-light", "league" ],
      [ study_program_path, "celestial-light", "word" ],
      [ church_path, "celestial-dark", "church" ],
      [ ward_profile_path(wards(:demo).code), "celestial-dark", "ward" ]
    ].each do |path, expected_theme, shot_name|
      visit path
      assert_selector "body > .home-menu.is-hud"
      assert_selector "body > .navigation-dock"
      assert_layout_chrome_full_width
      assert_hud_theme_contract(expected_theme)
      shot("hud-route-#{shot_name}")
    end
  end

  test "hub HUD renders the same anatomy in celestial light and dark" do
    sign_in_fixture_person_direct!(people(:pili))
    catalog = Array(YAML.safe_load_file(Hubs::Backdrop::CATALOG)["backdrops"])
    worlds = {
      "celestial-light" => catalog.find { |row| row["id"] == "eden-lumiere" },
      "celestial-dark" => catalog.find { |row| row["id"] == "coronas-ungido" }
    }

    worlds.each do |theme, row|
      Hubs::Backdrop.entries = [ row ]
      [ [ 390, 844 ], [ 768, 1024 ], [ 1440, 900 ] ].each do |width, height|
        set_quiz_viewport(width, height)
        visit root_path
        assert_selector "body.is-#{theme}"
        assert_hud_theme_contract(theme)
        assert_selector ".quiz-hud-who"
        assert_selector ".quiz-hud-pack"
        assert_selector ".quiz-hud-stats"
        assert_selector ".quiz-hud-menu"
        assert_hub_hud_polish!(centered_pack: width >= 600)
        find(".home-menu > .home-menu-btn").click
        assert_shared_menu_contract!(standard_mobile: width == 390 && height == 844)
        sleep 0.6
        shot("menu-hub-#{theme}-#{width}x#{height}")
        find(".chrome-drawer .is-drawer-close").click
        assert_no_selector "dialog.chrome-drawer[open]"
        shot("hud-#{theme}-#{width}x#{height}")
        assert_empty page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
      end
    end
  ensure
    Hubs::Backdrop.reset!
  end

  test "a long adventure title keeps Jouer inside the hero without covering the next tile" do
    sign_in_fixture_person_direct!(people(:pili))
    catalog = Array(YAML.safe_load_file(Hubs::Backdrop::CATALOG)["backdrops"])
    worlds = {
      "celestial-light" => catalog.find { |row| row["id"] == "eden-lumiere" },
      "celestial-dark" => catalog.find { |row| row["id"] == "coronas-ungido" }
    }

    worlds.each do |theme, row|
      Hubs::Backdrop.entries = [ row ]
      [ [ 390, 844 ], [ 768, 1024 ], [ 1440, 900 ] ].each do |width, height|
        set_quiz_viewport(width, height)
        visit root_path
        assert_selector "body.is-#{theme}"
        page.execute_script(<<~JS)
          document.querySelector(".hub-hero-title").textContent =
            "Abish, Sariah et les mères fidèles"
        JS

        geometry = page.evaluate_script(<<~JS)
          (function () {
            var stage = document.querySelector(".hub-hero-stage").getBoundingClientRect();
            var title = document.querySelector(".hub-hero-title");
            var titleBox = title.getBoundingClientRect();
            var titleStyle = getComputedStyle(title);
            var play = document.querySelector(".hub-play").getBoundingClientRect();
            var reward = document.querySelector(".hub-reward").getBoundingClientRect();
            var nextTile = document.querySelector(".hub-study, .hub-live").getBoundingClientRect();
            var install = document.querySelector(".hub-install:not([hidden])");
            var installBox = install && install.getBoundingClientRect();
            return {
              titleVisible: titleStyle.overflow != "hidden" &&
                [ "", "none" ].includes(titleStyle.webkitLineClamp),
              titleBottom: titleBox.bottom,
              titleWidth: titleBox.width,
              playTop: play.top,
              playBottom: play.bottom,
              rewardBottom: reward.bottom,
              stageBottom: stage.bottom,
              nextTop: nextTile.top,
              installGap: installBox ? stage.top - installBox.bottom : null
            };
          })()
        JS

        assert geometry["titleVisible"], "the complete adventure title should remain visible"
        assert_operator geometry["titleBottom"], :<, geometry["playTop"]
        assert_operator geometry["playBottom"], :<=, geometry["stageBottom"]
        assert_operator geometry["rewardBottom"], :<=, geometry["stageBottom"]
        assert_operator geometry["stageBottom"], :<=, geometry["nextTop"]
        assert_operator geometry["titleWidth"], :>=, 400 if width >= 720
        assert_operator geometry["installGap"], :>=, 12 if width == 390 && geometry["installGap"]
        shot("hub-long-title-#{theme}-#{width}x#{height}")
        assert_empty page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
      end
    end
  ensure
    Hubs::Backdrop.reset!
  end

  test "guest hub HUD shares the Street silhouette in celestial light and dark" do
    catalog = Array(YAML.safe_load_file(Hubs::Backdrop::CATALOG)["backdrops"])
    worlds = {
      "celestial-light" => catalog.find { |row| row["id"] == "eden-lumiere" },
      "celestial-dark" => catalog.find { |row| row["id"] == "coronas-ungido" }
    }

    clear_street_session!
    worlds.each do |theme, row|
      Hubs::Backdrop.entries = [ row ]
      [ [ 390, 844 ], [ 768, 1024 ], [ 1440, 900 ] ].each do |width, height|
        set_quiz_viewport(width, height)
        visit root_path
        assert_selector "body.is-#{theme}"
        assert_selector ".home-menu.is-hud .quiz-hud.is-guest"
        assert_street_hud_radius!
        shot("hud-guest-#{theme}-#{width}x#{height}")
        assert_empty page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
      end
    end
  ensure
    Hubs::Backdrop.reset!
  end

  test "the challenge page keeps the next pack readable across reference viewports" do
    set_quiz_viewport(390, 844)
    pili = people(:pili)
    invitation = DuelInvitation.create!(
      challenger_person: people(:carmen_garcia), recipient_person: pili,
      challenger_score: 61, token_digest: SecureRandom.hex(32), status: "open",
      expires_at: 7.days.from_now
    )
    storm_rival = people(:carmen_lopez)
    storm_invitation = DuelInvitation.create!(
      challenger_person: pili, recipient_person: storm_rival,
      challenger_score: 65, claimed_by_person: storm_rival,
      token_digest: SecureRandom.hex(32), status: "claimed", claimed_at: 2.days.ago,
      expires_at: 7.days.from_now
    )
    storm_mine_run = QuizRun.create!(
      person: pili, device_digest: Digest::SHA256.hexdigest("duel-campus-storm-mine"),
      pack_id: "milagros", position: 10, score: 65, opened_at: 3.days.ago, status: "finished"
    )
    storm_rival_run = QuizRun.create!(
      person: storm_rival, device_digest: Digest::SHA256.hexdigest("duel-campus-storm-rival"),
      pack_id: "coronas", position: 10, score: 95, opened_at: 3.days.ago, status: "finished"
    )
    storm_duel = StreetDuel.create!(
      challenger_person: pili, opponent_person: storm_rival,
      challenger_run: storm_mine_run, opponent_run: storm_rival_run,
      challenger_score: 65, opponent_score: 95, status: "resolved",
      accepted_at: 3.days.ago, resolved_at: 2.days.ago, expires_at: 7.days.from_now,
      origin_invitation: storm_invitation
    )
    storm_invitation.update!(street_duel: storm_duel)
    sign_in_fixture_person_direct!(pili)
    visit street_challenges_path
    page.execute_script("window.scrollTo(0, 0)")

    assert_no_horizontal_layout_overflow
    assert_selector ".duel-campus"
    assert_selector "body.is-celestial-dark"
    assert_selector ".home-menu.is-hud[data-hud-theme='celestial-dark']"
    assert_selector ".duel-campus-world-picture img[src*='/media/generated/catalog/social/campus-scriptures-celestial-dark-v1/']"
    assert_no_selector ".duel-campus-hero-art"
    assert_no_selector "img[src^='/media/ui/duel-campus/']"
    %w[crown duel-books duel-scrolls duel-staffs book].each { |icon| assert_selector ".picto-#{icon}" }
    assert_no_selector ".duel-campus-section.is-active"
    assert_selector ".duel-campus-section.is-incoming"
    assert_selector "time.duel-campus-invitation-date", text: /#{Regexp.escape(I18n.l(invitation.expires_at.to_date))}/
    assert_selector ".duel-campus-section.is-results h2", text: I18n.t("duel_campus.sections.results")
    assert_selector ".duel-campus-card.is-result", minimum: 2
    assert_selector ".duel-campus-card.is-result.is-ahead.is-gap-decisive.has-result-scene"
    assert_selector ".duel-campus-card.is-result.is-behind.is-gap-blowout.has-result-scene"
    assert_selector ".duel-campus-result-faceoff", minimum: 2
    assert_selector ".duel-campus-result-side.is-me", text: /#{Regexp.escape(I18n.t("duel_campus.labels.me"))}/i, minimum: 2
    assert_selector ".duel-campus-result-side.is-rival", minimum: 2
    assert_selector ".duel-campus-result-versus", text: I18n.t("duel_campus.labels.versus"), minimum: 2
    assert_selector ".is-ahead .duel-campus-result-art img[src*='/media/generated/catalog/social/duel-results-victory-arena-v1/']"
    assert_selector ".is-behind .duel-campus-result-art img[src*='/media/generated/catalog/social/duel-results-storm-arena-v2/']"
    assert_selector ".duel-campus-section.is-friends"
    assert_selector ".duel-campus-section.is-outgoing"
    assert_selector ".duel-campus-priority", text: /#{Regexp.escape(I18n.t("duel_campus.priority.kicker"))}/i
    assert_equal "fixed", page.evaluate_script("getComputedStyle(document.querySelector('.duel-campus-world-art')).position")
    assert_equal "46%", page.evaluate_script("getComputedStyle(document.querySelector('.duel-campus-world-picture img')).objectPosition.split(' ')[1]")
    assert_equal "none", page.evaluate_script("getComputedStyle(document.querySelector('.duel-campus-world-picture img')).filter")
    assert_no_selector ".duel-campus-world-art > span"
    assert_equal "rgba(0, 0, 0, 0)", page.evaluate_script("getComputedStyle(document.querySelector('.duel-campus-hero-copy')).backgroundColor")
    hero_geometry = page.evaluate_script(<<~JS)
      (function() {
        const hero = document.querySelector('.duel-campus-hero').getBoundingClientRect()
        const scrim = document.querySelector('.duel-campus-hero-scrim').getBoundingClientRect()
        return { heroTop: hero.top, heroHeight: hero.height, scrimTop: scrim.top }
      })()
    JS
    assert_operator hero_geometry["heroHeight"], :>=, 350
    assert_operator hero_geometry["scrimTop"], :>, hero_geometry["heroTop"] + (hero_geometry["heroHeight"] * 0.3)
    action_geometry = page.evaluate_script(<<~JS)
      (function() {
        const priority = document.querySelector('.duel-campus-priority-action').getBoundingClientRect()
        const accept = document.querySelector('.duel-campus-card-actions .duel-campus-command').getBoundingClientRect()
        return { priorityHeight: priority.height, acceptHeight: accept.height, acceptWidth: accept.width }
      })()
    JS
    assert_in_delta 46, action_geometry["priorityHeight"], 1
    assert_operator action_geometry["acceptHeight"], :>=, 44
    assert_operator action_geometry["acceptHeight"], :<=, 48
    assert_operator action_geometry["acceptWidth"], :<, 230

    [
      [ 390, 844 ],
      [ 520, 844 ],
      [ 521, 900 ],
      [ 759, 1024 ],
      [ 760, 1024 ],
      [ 900, 1024 ],
      [ 901, 1024 ],
      [ 1099, 900 ],
      [ 1100, 900 ],
      [ 1440, 900 ]
    ].each do |width, height|
      set_quiz_viewport(width, height)
      assert_duel_priority_clears_summary!(width:)
    end
    set_quiz_viewport(390, 844)
    shot("duel-campus-390x844")
    page.execute_script("document.querySelector('.duel-campus-section.is-results').scrollIntoView({ block: 'start' })")
    page.execute_script("window.scrollBy(0, -72)")
    wait_for_image!(".is-ahead .duel-campus-result-art img")
    wait_for_image!(".is-behind .duel-campus-result-art img")
    assert_no_horizontal_layout_overflow
    shot("duel-campus-results-390x844")
    page.execute_script("document.querySelector('.duel-campus-section.is-outgoing').scrollIntoView({ block: 'start' })")
    shot("duel-campus-outgoing-390x844")

    set_quiz_viewport(768, 1024)
    page.scroll_to(:top)
    wait_for_image!(".duel-campus-world-picture img")
    assert_no_horizontal_layout_overflow
    assert_outgoing_section_uses_available_width
    assert_operator page.evaluate_script("document.querySelector('.duel-campus-hero-copy').getBoundingClientRect().bottom"), :<, 1024
    shot("duel-campus-768x1024")
    page.execute_script("document.querySelector('.duel-campus-section.is-results').scrollIntoView({ block: 'start' })")
    page.execute_script("window.scrollBy(0, -72)")
    wait_for_image!(".is-ahead .duel-campus-result-art img")
    wait_for_image!(".is-behind .duel-campus-result-art img")
    assert_no_horizontal_layout_overflow
    shot("duel-campus-results-768x1024")
    page.execute_script("document.querySelector('.duel-campus-section.is-outgoing').scrollIntoView({ block: 'start' })")
    shot("duel-campus-outgoing-768x1024")

    set_quiz_viewport(1440, 900)
    page.scroll_to(:top)
    wait_for_image!(".duel-campus-world-picture img")
    assert_no_horizontal_layout_overflow
    assert_outgoing_section_uses_available_width
    assert_operator page.evaluate_script("document.querySelector('.duel-campus').getBoundingClientRect().width"), :>=, 1100
    shot("duel-campus-1440x900")
    page.execute_script("document.querySelector('.duel-campus-section.is-results').scrollIntoView({ block: 'start' })")
    page.execute_script("window.scrollBy(0, -72)")
    wait_for_image!(".is-ahead .duel-campus-result-art img")
    wait_for_image!(".is-behind .duel-campus-result-art img")
    assert_no_horizontal_layout_overflow
    shot("duel-campus-results-1440x900")
    page.execute_script("document.querySelector('.duel-campus-section.is-outgoing').scrollIntoView({ block: 'start' })")
    shot("duel-campus-outgoing-1440x900")
    assert_empty page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
    set_quiz_viewport(390, 844)
  end

  test "an active challenge names the live rivals pack progress and points" do
    set_quiz_viewport(390, 844)
    pili = people(:pili)
    carmen = people(:carmen_garcia)
    invitation = DuelInvitation.create!(
      challenger_person: pili, recipient_person: carmen,
      token_digest: SecureRandom.hex(32), status: "claimed", claimed_by_person: carmen,
      claimed_at: 10.minutes.ago, expires_at: 7.days.from_now
    )
    duel = StreetDuel.create!(
      challenger_person: pili, opponent_person: carmen,
      status: "active", accepted_at: 10.minutes.ago, expires_at: 7.days.from_now,
      origin_invitation: invitation
    )
    invitation.update!(street_duel: duel)
    run = quiz_runs(:carmen_milagros)
    run.update!(status: "open", position: 6, score: 41, opened_at: 5.minutes.ago)
    Presences::Registry.enter(connection_id: "visual:carmen-active", person_id: carmen.id, role: "street")
    sign_in_fixture_person_direct!(pili)

    visit street_challenges_path

    assert_no_horizontal_layout_overflow
    assert_selector ".duel-campus-card.is-duel.is-ready", text: /#{Regexp.escape(run.pack.copy(:title))}/
    assert_selector ".duel-campus-live", text: /#{Regexp.escape(I18n.t("duel_campus.states.live"))}/i
    assert_selector ".duel-campus-card-status", text: %r{6/10}
    assert_selector ".duel-campus-section.is-active.is-visible"
    shot("duel-campus-active-phone")
    assert_empty page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
  ensure
    Presences::Registry.reset!
  end

  test "a waiting duel keeps its next move above the dock at every reference viewport" do
    pili = people(:pili)
    rival = people(:carmen_lopez)
    invitation = DuelInvitation.create!(
      challenger_person: pili, recipient_person: rival,
      token_digest: SecureRandom.hex(32), status: "claimed", claimed_by_person: rival,
      claimed_at: 10.minutes.ago, expires_at: 7.days.from_now
    )
    run = QuizRun.create!(
      person: pili, device_digest: Digest::SHA256.hexdigest("duel-detail-visual"),
      pack_id: "coronas", position: 10, score: 95, status: "finished", opened_at: 20.minutes.ago
    )
    duel = StreetDuel.create!(
      challenger_person: pili, opponent_person: rival,
      challenger_run: run, challenger_score: 95,
      origin_invitation: invitation, status: "one_scored",
      accepted_at: 10.minutes.ago, expires_at: 7.days.from_now
    )
    invitation.update!(street_duel: duel)
    sign_in_fixture_person_direct!(pili)
    page.driver.browser.manage.add_cookie(name: Locale::COOKIE.to_s, value: "fr", path: "/")

    [ [ 390, 844 ], [ 768, 1024 ], [ 1440, 900 ] ].each do |width, height|
      set_quiz_viewport(width, height)
      visit street_duel_path(duel)

      assert_selector ".duel-detail[data-motion-state='ready']"
      assert_selector ".duel-detail-status.is-waiting", text: /#{Regexp.escape(rival.given_name)}/
      assert_selector ".duel-detail-actions .btn", text: I18n.t("duel_campus.actions.play_any_pack", locale: :fr)
      assert_no_horizontal_layout_overflow
      geometry = page.evaluate_script(<<~JS)
        (function() {
          const sheet = document.querySelector('.duel-detail-sheet').getBoundingClientRect()
          const world = document.querySelector('.duel-detail-world').getBoundingClientRect()
          const primary = document.querySelector('.duel-detail-actions .btn').getBoundingClientRect()
          const back = document.querySelector('.duel-detail-actions .quiet-link').getBoundingClientRect()
          const dock = document.querySelector('.navigation-dock').getBoundingClientRect()
          return {
            sheetBottom: sheet.bottom,
            worldLeft: world.left,
            worldRight: world.right,
            worldBottom: world.bottom,
            viewportWidth: document.documentElement.clientWidth,
            primaryHeight: primary.height,
            backHeight: back.height,
            dockTop: dock.top
          }
        })()
      JS
      assert_operator geometry["sheetBottom"], :<, geometry["dockTop"]
      assert_operator geometry["worldLeft"].abs, :<=, 1
      assert_operator geometry["worldRight"], :>=, geometry["viewportWidth"] - 1
      assert_operator geometry["worldBottom"], :>=, geometry["dockTop"]
      assert_operator geometry["primaryHeight"], :>=, 44
      assert_operator geometry["backHeight"], :>=, 44
      shot("duel-waiting-#{width}x#{height}")
    end

    assert_empty page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
    set_quiz_viewport(390, 844)
    page.driver.browser.execute_cdp(
      "Emulation.setEmulatedMedia",
      media: "screen",
      features: [ { name: "prefers-reduced-motion", value: "reduce" } ]
    )
    visit street_duel_path(duel)
    assert_equal "none", page.evaluate_script("getComputedStyle(document.querySelector('.duel-detail-versus'), '::after').animationName")
  ensure
    if self.class.chrome_binary
      page.driver.browser.execute_cdp(
        "Emulation.setEmulatedMedia",
        media: "screen",
        features: [ { name: "prefers-reduced-motion", value: "no-preference" } ]
      )
    end
  end

  test "the French challenge page keeps compact actions and native copy" do
    set_quiz_viewport(390, 844)
    pili = people(:pili)
    invitation = DuelInvitation.create!(
      challenger_person: people(:carmen_garcia), recipient_person: pili,
      challenger_score: 61, token_digest: SecureRandom.hex(32), status: "open",
      expires_at: 7.days.from_now
    )
    sign_in_fixture_person_direct!(pili)
    page.driver.browser.manage.add_cookie(name: Locale::COOKIE.to_s, value: "fr", path: "/")

    visit street_challenges_path

    assert_selector "h1", text: I18n.t("duel_campus.title", locale: :fr)
    assert_selector ".duel-campus-priority", text: /#{Regexp.escape(I18n.t("duel_campus.priority.kicker", locale: :fr))}/i
    assert_no_horizontal_layout_overflow
    action_height = page.evaluate_script("document.querySelector('.duel-campus-priority-action').getBoundingClientRect().height")
    assert_in_delta 46, action_height, 1
    assert_selector "time.duel-campus-invitation-date", text: /#{Regexp.escape(I18n.l(invitation.expires_at.to_date, locale: :fr))}/
    assert_selector ".duel-campus-card-actions .duel-campus-command", text: I18n.t("duel_campus.actions.accept", locale: :fr)
    assert_selector ".duel-campus-section.is-friends.is-visible"
    shot("duel-campus-fr-phone")
    click_button I18n.t("duel_campus.actions.play_pack", locale: :fr)
    assert_selector "#street_quiz"
  end

  test "the Scripture Campus exposes its final state with reduced motion" do
    set_quiz_viewport(390, 844)
    page.driver.browser.execute_cdp(
      "Emulation.setEmulatedMedia",
      media: "screen",
      features: [ { name: "prefers-reduced-motion", value: "reduce" } ]
    )
    sign_in_fixture_person_direct!(people(:pili))
    visit street_challenges_path

    assert_selector ".duel-campus[data-motion-state='ready']"
    assert_no_selector ".duel-campus.has-motion"
    states = page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll('.duel-campus-section')).map((section) => {
        const style = getComputedStyle(section)
        return {
          opacity: style.opacity,
          transform: style.transform,
          transitionDuration: style.transitionDuration,
          visible: section.classList.contains('is-visible')
        }
      })
    JS
    assert states.all? { |state| state["opacity"] == "1" }
    assert states.all? { |state| state["transform"] == "none" }
    assert states.all? { |state| state["transitionDuration"] == "0s" }
    assert states.all? { |state| state["visible"] }
    shot("duel-campus-reduced-motion")
  ensure
    if self.class.chrome_binary
      page.driver.browser.execute_cdp(
        "Emulation.setEmulatedMedia",
        media: "screen",
        features: [ { name: "prefers-reduced-motion", value: "no-preference" } ]
      )
    end
  end

  test "the Street quiz exposes complete ask and result states with reduced motion" do
    set_quiz_viewport(390, 844)
    page.driver.browser.execute_cdp(
      "Emulation.setEmulatedMedia",
      media: "screen",
      features: [ { name: "prefers-reduced-motion", value: "reduce" } ]
    )
    ready_street_quiz!

    assert_no_selector "#street_quiz.is-art-preview"
    assert_no_selector "#street_quiz.is-entering"
    assert_selector ".choice-btn", minimum: 3
    first(".choice-btn").click
    assert_selector "#street_quiz.is-result-sequence.is-feedback-ready.is-reward-ready.is-actions-ready"
    assert_selector ".street-shot-actions", visible: true

    moving = page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll('#street_quiz *')).filter((element) => {
        const style = getComputedStyle(element)
        return style.animationName && style.animationName !== 'none' &&
          style.animationDuration && style.animationDuration !== '0s'
      }).map((element) => {
        const style = getComputedStyle(element)
        return {
          tag: element.tagName.toLowerCase(),
          className: typeof element.className === 'string' ? element.className : '',
          animationName: style.animationName,
          animationDuration: style.animationDuration
        }
      })
    JS
    assert_empty moving, "reduced-motion Street state must not leave decorative animations running"
  ensure
    if self.class.chrome_binary
      page.driver.browser.execute_cdp(
        "Emulation.setEmulatedMedia",
        media: "screen",
        features: [ { name: "prefers-reduced-motion", value: "no-preference" } ]
      )
    end
  end

  test "the living fire poster keeps the result playable without video" do
    set_quiz_viewport(390, 844)
    ready_street_quiz!

    right = page.all(".choice-btn").find { |btn| btn["data-choice-key"] == find("#street_quiz")["data-quiz-correct-value"] }
    right.click
    assert_selector "#street_quiz.is-actions-ready .street-hit-poster[src*='living-fire-poster-v1.webp']", visible: true

    page.execute_script("document.querySelector('.street-hit-video')?.remove()")

    assert_no_selector ".street-hit-video", visible: :all
    assert_selector ".street-hit-poster[src*='living-fire-poster-v1.webp']", visible: true
    assert_selector ".street-hit-value.is-gain", text: "+5"
    assert_selector ".street-hit-points", text: /\+5/
    assert_selector ".street-shot-actions .quiz-next", visible: true
    assert_hit_performance_geometry!
  end

  test "jugar ask has no chase chip on the still" do
    set_system_viewport(390, 844)
    sign_in_fixture_person_direct!(people(:pili))
    assert_no_selector "#profile_gate"
    assert_selector ".street-map-door-play", wait: 5
    find(".street-map-door-play").click
    assert_selector "#street_quiz.play-reel.is-quiz.is-street.is-overlay"
    assert_no_selector ".street-shot-rival"
    assert_selector ".quiz-hud-avatar"
    assert_selector ".home-menu.is-split .home-menu-btn"
    assert_no_selector ".chrome-tools"
    assert_jugar_chrome_on_column
    page.execute_script("document.querySelector('#street_quiz')?.classList.add('is-art-preview')")
    assert_equal "hidden", page.evaluate_script("getComputedStyle(document.querySelector('#street_quiz .quiz-dock')).visibility")
    sleep 0.5
    shot("01-ask-phone")
    page.execute_script("document.querySelector('#street_quiz')?.classList.remove('is-art-preview')")
    assert_equal "none", page.evaluate_script("getComputedStyle(document.querySelector('#street_quiz .quiz-sheet')).backdropFilter")
    assert_equal "street-question-card", page.evaluate_script("getComputedStyle(document.querySelector('#street_quiz .quiz-sheet')).viewTransitionName")
  end

  test "jugar HUD keeps the player level attached and the pack truly centered" do
    set_quiz_viewport(390, 844)
    ready_street_quiz!
    run = QuizRun.open_runs.where(person: people(:pili)).order(:id).last
    image = run.question.presentation&.[]("image").to_s
    chrome_rows = Quizzes::Chrome.stills.deep_dup

    %w[light dark].each do |theme|
      Quizzes::Chrome.stills = chrome_rows.merge(image => chrome_rows.fetch(image, {}).merge("mode" => theme))
      visit jugar_path
      assert_selector "#street_quiz[data-quiz-theme=#{theme}] .quiz-hud.is-quiz"
      assert_selector ".quiz-hud-name .quiz-hud-level"
      assert_no_selector ".quiz-hud > .quiz-hud-level"

      [ [ 390, 844 ], [ 768, 1024 ], [ 1440, 900 ] ].each do |width, height|
        set_quiz_viewport(width, height)
        wait_for_image!("#street_quiz .challenge-story")
        assert_jugar_chrome_on_column
        assert_no_horizontal_layout_overflow
        shot("jugar-hud-#{theme}-#{width}x#{height}")
        find(".home-menu > .home-menu-btn").click
        assert_shared_menu_contract!(standard_mobile: width == 390 && height == 844)
        sleep 0.6
        shot("menu-jugar-#{theme}-#{width}x#{height}")
        find(".chrome-drawer .is-drawer-close").click
        assert_no_selector "dialog.chrome-drawer[open]"
      end

      assert_empty page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
    end
  ensure
    Quizzes::Chrome.reset!
    set_quiz_viewport(390, 844) if self.class.chrome_binary
  end

  test "the friendly duel race stays above the quiz in light and dark chrome" do
    set_quiz_viewport(390, 844)
    pili = people(:pili)
    carmen = people(:carmen_garcia)
    friend_run = QuizRun.create!(
      device_digest: "duel-race-visual-friend", person: carmen, pack_id: "placas",
      position: 10, score: 93, status: "finished", opened_at: 1.hour.ago
    )
    invitation = DuelInvitation.create!(
      challenger_person: carmen, recipient_person: pili,
      challenger_run: friend_run, challenger_score: friend_run.score,
      token_digest: SecureRandom.hex(32), status: "open", expires_at: 7.days.from_now
    )
    Quizzes::DuelInvitationClaim.call(invitation:, person: pili)
    sign_in_fixture_person_direct!(pili)
    find(".street-map-door-play").click if page.has_css?(".street-map-door-play", wait: 2)
    assert_selector "#street_quiz.play-reel.is-quiz.is-street"
    run = QuizRun.open_runs.order(:id).last
    run.update!(position: 4, ends_at: 20.seconds.from_now)
    image = run.question.presentation&.[]("image").to_s
    chrome_rows = Quizzes::Chrome.stills.deep_dup
    page.execute_script("Object.keys(sessionStorage).filter((key) => key.startsWith('noche:duel-race:')).forEach((key) => sessionStorage.removeItem(key))")

    Quizzes::Chrome.stills = chrome_rows.merge(image => chrome_rows.fetch(image, {}).merge("mode" => "light"))
    visit jugar_path
    assert_selector "#street_quiz[data-quiz-theme=light] .duel-quiz-rail.is-chasing"
    assert_selector ".duel-quiz-rail.is-race-expanded.is-race-presenting", wait: 2
    assert_equal "duel-rail-present", page.evaluate_script("getComputedStyle(document.querySelector('.duel-quiz-rail-main')).animationName")
    assert_no_selector "#street_quiz.is-art-preview", wait: 2
    wait_for_image!("#street_quiz .challenge-story")
    sleep 0.7
    assert_duel_race_geometry!
    expanded = duel_race_dimensions
    shot("duel-race-390x844-light-expanded")

    assert_selector ".duel-quiz-rail.is-race-compact", wait: 5
    sleep 0.5
    compact = duel_race_dimensions
    assert_operator compact["width"], :<, expanded["width"]
    assert_operator compact["height"], :<, expanded["height"]
    assert_duel_race_geometry!
    shot("duel-race-390x844-light")

    run.update!(ends_at: 20.seconds.from_now)
    Quizzes::Chrome.stills = chrome_rows.merge(image => chrome_rows.fetch(image, {}).merge("mode" => "dark"))
    visit jugar_path
    assert_selector "#street_quiz[data-quiz-theme=dark] .duel-quiz-rail.is-chasing.is-race-compact.is-race-instant"
    assert_no_selector ".duel-quiz-rail.is-race-presenting"
    assert_no_selector "#street_quiz.is-art-preview", wait: 2
    wait_for_image!("#street_quiz .challenge-story")
    assert_duel_race_geometry!
    shot("duel-race-390x844-dark")

    set_quiz_viewport(768, 1024)
    wait_for_image!("#street_quiz .challenge-story")
    assert_duel_race_geometry!
    shot("duel-race-768x1024-dark")

    set_quiz_viewport(1440, 900)
    wait_for_image!("#street_quiz .challenge-story")
    assert_duel_race_geometry!
    shot("duel-race-1440x900-dark")

    set_quiz_viewport(390, 844)
    page.driver.browser.execute_cdp(
      "Emulation.setEmulatedMedia",
      media: "screen",
      features: [ { name: "prefers-reduced-motion", value: "reduce" } ]
    )
    page.execute_script("Object.keys(sessionStorage).filter((key) => key.startsWith('noche:duel-race:')).forEach((key) => sessionStorage.removeItem(key))")
    visit jugar_path
    assert_selector ".duel-quiz-rail.is-race-compact.is-race-instant"
    moving = page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll('.duel-quiz-rail, .duel-quiz-rail *')).filter((element) => {
        const style = getComputedStyle(element)
        return style.animationName !== 'none' && style.animationDuration !== '0s'
      }).map((element) => element.className)
    JS
    assert_empty moving, "reduced-motion duel reminder must not leave decorative animations running"
    assert_duel_race_geometry!
    shot("duel-race-390x844-reduced-motion")
    assert_empty page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
  ensure
    Quizzes::Chrome.reset!
    if self.class.chrome_binary
      page.driver.browser.execute_cdp(
        "Emulation.setEmulatedMedia",
        media: "screen",
        features: [ { name: "prefers-reduced-motion", value: "no-preference" } ]
      )
      set_quiz_viewport(390, 844)
    end
  end

  test "jugar uses the same shared menu as the hub" do
    set_system_viewport(390, 844)
    ready_street_quiz!
    find(".home-menu-btn").click
    assert_selector "dialog.chrome-drawer[open] .home-menu-nav-hub"
    assert_selector ".home-menu-invite[href='#{street_challenges_path(anchor: "inviter")}']", text: I18n.t("hub_menu.invite_friend")
    assert_selector ".home-menu-row[href='#{street_leaderboard_path}']", text: I18n.t("hub_menu.leaderboard")
    assert_selector ".home-menu-row[href='#{study_program_path}']", text: I18n.t("study.title")
    assert_selector ".hub-menu-legal a", count: 3
    find(".home-menu-invite").click
    assert_selector "#inviter.duel-campus-section.is-friends"
    assert_equal "#inviter", page.evaluate_script("window.location.hash")
  end

  test "hub pulse receives live count without polling or leaving the hub" do
    set_system_viewport(390, 844)
    visit root_path
    assert_selector ".street-pulse[data-pulse-online='0']"
    assert_selector "#street_world"
    change = Presences::Registry.enter(
      connection_id: "system-live-pulse",
      person_id: people(:pili).id,
      ward_id: people(:pili).ward_id,
      role: "test"
    )
    Presences::BroadcastChange.call(change)
    assert_selector ".street-pulse[data-pulse-online='1']", wait: 5
    assert_selector "#street_world"
    assert_no_selector "#street_quiz"
  end

  test "hub league strip with signed-in profile" do
    set_quiz_viewport(390, 844)
    person = people(:pili)
    sign_in_fixture_person_direct!(person)
    token = PersonDevice.where(person:).order(:id).last&.device_token
    digest = GameSession.digest_token(token) if token.present?
    if digest
      QuizRun.create!(
        device_digest: digest,
        person:,
        pack_id: QuizDefinition.catalog.pack_ids.first,
        position: 10,
        score: 80,
        status: "finished",
        opened_at: Time.current
      )
    end
    QuizRun.create!(
      device_digest: "hub-league-lopez",
      person: people(:carmen_lopez),
      pack_id: QuizDefinition.catalog.pack_ids.first,
      position: 10,
      score: 70,
      status: "finished",
      opened_at: Time.current
    )
    visit root_path
    assert_no_selector "#profile_gate"
    assert_selector ".quiz-hud"
    assert_no_selector ".hub-mini"
    assert_selector ".hub-online.is-empty"
    assert_selector ".hub-online-ranking.street-league"
    assert_selector ".quiz-hud-name", text: person.given_name
    assert_selector ".quiz-hud-rank"
    assert_no_selector ".street-xp-bar"
    assert_selector ".street-card.is-map-door"
    assert_selector ".street-map-door-kicker"
    assert_selector ".hub-hero-stage"
    assert_selector ".hub-hero-continue"
    assert_selector ".hub-reward-label"
    assert_selector ".hub-reward img.hub-reward-chest"
    assert_selector ".street-map-door-play", text: /#{Regexp.escape(I18n.t("street.world_play"))}/i
    assert_selector ".street-pulse"
    assert_no_selector ".navigation-dock .street-play-cta"
    assert_no_selector ".street-map-door-open"
    assert_selector ".street-map-door-step"
    assert_selector ".street-rank-banner", count: 0
    assert_selector ".quiz-hud-rank"
    page.execute_script("window.scrollTo(0, 0)")
    sleep 0.6
    find(".home-menu-btn").click
    assert_selector "dialog.chrome-drawer[open] .home-menu-nav-hub"
    assert_selector ".quiz-hud-avatar"
    assert_selector ".home-menu-invite", text: I18n.t("hub_menu.invite_friend")
    assert_selector ".home-menu-row", text: I18n.t("study.title")
    assert_selector ".home-menu-row", text: I18n.t("hub_menu.my_ward")
    shot("hub-menu-phone")
    find(".chrome-drawer .is-drawer-close").click
    assert_no_selector "dialog.chrome-drawer[open]"
    assert_hub_shell_pinned
    assert_above_hub_dock ".hub-hero"
    assert_above_hub_dock ".street-card.is-map-door"
    assert_no_selector ".chrome-tools"
    assert_selector ".navigation-dock a.navigation-dock__item", count: 5
    assert_selector ".navigation-dock a[href='/']"
    assert_selector ".navigation-dock a[href='/mapa']"
    assert_selector ".navigation-dock a[href='/parole']"
    assert_selector ".navigation-dock a[href='/iglesia']"
    assert_selector ".navigation-dock__item[href='/parole'] > .picto-scripture-book"
    assert_no_selector ".street-hub-word-medallion"
    assert_no_selector ".navigation-dock .picto-bell"
    assert_no_selector ".hub-shortcuts"
    assert_layout_chrome_full_width
    assert_no_horizontal_layout_overflow
    shot("hub-league-phone")
    shot("hub-phone")
    open_hub_map_from_dock
    assert_selector ".street-map-page"
    assert_selector ".mapa-mission"
    assert_selector ".mapa-mission-progress[role='progressbar']"
    assert_selector ".mapa-continue", text: I18n.t("hub.continue")
    assert_no_selector ".mapa-stats-row"
    assert_selector ".mapa-tab[aria-selected='true']", count: 1
    assert_selector ".mapa-node", count: QuizDefinition.catalog.pack_ids.size
    assert_selector ".mapa-node.is-current"
    assert_selector ".mapa-node.is-locked"
    assert_no_selector ".mapa-node.is-locked .mapa-node-hit"
    sleep 0.8
    assert_no_horizontal_layout_overflow
    assert_operator page.evaluate_script("window.scrollY"), :<=, 8
    map_title_gap = page.evaluate_script(<<~JS)
      document.querySelector('.mapa-heading').getBoundingClientRect().top -
        document.querySelector('.home-menu.is-hud').getBoundingClientRect().bottom
    JS
    assert_operator map_title_gap, :>=, 16
    shot("map-phone")
    find(".navigation-dock a[href='/']").click
    assert_selector ".street-card.is-map-door"
    assert_abuelo_type_floor
    [
      [ 768, 1024, "hub-ipad" ],
      [ 1024, 768, "hub-ipad-land" ],
      [ 1280, 800, "hub-desktop" ],
      [ 1920, 1080, "hub-xl" ]
    ].each do |width, height, name|
      set_quiz_viewport(width, height)
      sleep 0.35
      assert_layout_chrome_full_width
      assert_abuelo_type_floor
      shot(name)
    end
    set_quiz_viewport(390, 844)
  end

  test "challenge page keeps its points race above the mobile dock" do
    set_system_viewport(390, 844)
    sign_in_fixture_person_direct!(people(:pili))
    visit street_challenges_path

    assert_no_horizontal_layout_overflow
    assert_selector "body.is-duel-campus"
    assert_selector "body.is-celestial-dark"
    assert_selector ".duel-campus-world-picture img[src*='/media/generated/catalog/social/campus-scriptures-celestial-dark-v1/']"
    assert_selector "h1", text: I18n.t("duel_campus.title")
    assert_selector ".duel-campus-priority-meta", text: /89/
    assert_selector ".duel-campus-section.is-friends"
    sleep 0.4
    shot("duel-campus-phone")
    set_system_viewport(390, 844)
  end

  test "friendly invitation leaves its lower composition to the actions" do
    set_quiz_viewport(390, 844)
    invitation = duel_invitations(:open_pili_invitation)
    visit street_challenge_path(invitation.public_token)

    assert_selector "body.is-duel-invitation"
    assert_selector ".duel-invitation-hero img[src*='/media/generated/catalog/social/campus-invitation-friends-v1/']"
    assert_selector ".duel-invitation-sheet .btn-gold.duel-campus-command", text: I18n.t("duel_campus.actions.accept")
    assert_selector "time.duel-campus-invitation-date", text: /#{Regexp.escape(I18n.l(invitation.expires_at.to_date))}/
    command = page.evaluate_script("document.querySelector('.duel-invitation-primary').getBoundingClientRect().toJSON()")
    assert_operator command["height"], :>=, 44
    assert_operator command["height"], :<=, 48
    assert_operator command["width"], :<=, 320
    assert_no_horizontal_layout_overflow
    shot("duel-invitation-phone")
  end

  test "a returning friend keeps every invitation action above the dock" do
    set_quiz_viewport(390, 844)
    recipient = people(:carmen_garcia)
    sign_in_fixture_person_direct!(recipient)
    invitation = DuelInvitation.create!(
      challenger_person: people(:pili), recipient_person: recipient,
      challenger_score: 61, token_digest: SecureRandom.hex(32), status: "open", expires_at: 7.days.from_now
    )
    visit street_challenge_path(invitation.public_token)

    assert_selector ".duel-invitation.has-dock .duel-invitation-actions .btn", count: 2
    geometry = page.evaluate_script(<<~JS)
      (function() {
        var actions = document.querySelector('.duel-invitation-actions').getBoundingClientRect();
        var rule = document.querySelector('.duel-invitation-rule').getBoundingClientRect();
        var dock = document.querySelector('.navigation-dock').getBoundingClientRect();
        return {
          actionsTop: actions.top,
          actionsBottom: actions.bottom,
          ruleBottom: rule.bottom,
          dockTop: dock.top
        };
      })()
    JS
    assert_operator geometry["ruleBottom"], :<, geometry["actionsTop"]
    assert_operator geometry["actionsBottom"], :<, geometry["dockTop"]
    assert_no_horizontal_layout_overflow
    shot("duel-invitation-returning-phone")
  end

  test "a challenge signal owns the safe zone above the dock" do
    set_quiz_viewport(390, 844)
    carmen = people(:carmen_garcia)
    sign_in_fixture_person_direct!(carmen)
    invitation = DuelInvitation.create!(
      challenger_person: people(:pili), recipient_person: carmen,
      challenger_score: 61, token_digest: SecureRandom.hex(32), status: "open", expires_at: 7.days.from_now
    )
    html = ApplicationController.render(
      partial: "street_challenges/ping",
      locals: { invitation:, viewer: carmen }
    )
    page.execute_script(<<~JS)
      document.querySelector('#duel_campus_notice').outerHTML = #{html.to_json};
    JS

    assert_selector "#duel_campus_notice.duel-campus-notice", text: /#{Regexp.escape(people(:pili).display_name)}/
    geometry = page.evaluate_script(<<~JS)
      (function() {
        var signal = document.querySelector('#duel_campus_notice');
        var dock = document.querySelector('.navigation-dock');
        var s = signal.getBoundingClientRect();
        var d = dock.getBoundingClientRect();
        return {
          signalBottom: s.bottom,
          dockTop: d.top,
          signalZ: Number(getComputedStyle(signal).zIndex),
          dockZ: Number(getComputedStyle(dock).zIndex)
        };
      })()
    JS
    assert_operator geometry["signalBottom"], :<, geometry["dockTop"]
    assert_operator geometry["signalZ"], :>, geometry["dockZ"]
    shot("challenge-signal-phone")
  end

  test "resolved duel offers a rematch without naming or forcing a pack" do
    set_quiz_viewport(390, 844)
    sign_in_fixture_person_direct!(people(:pili))
    visit street_duel_path(street_duels(:pili_vs_carmen))

    assert_selector ".duel-detail-verdict"
    assert_selector "form[action='#{street_duel_rematch_path(street_duels(:pili_vs_carmen))}']"
    assert_no_text QuizDefinition.catalog.find_pack("coronas").copy(:title)
    assert_no_horizontal_layout_overflow
    shot("duel-result-phone")
  end

  test "liga name search filters as you type" do
    set_system_viewport(390, 844)
    sign_in_fixture_person_direct!(people(:pili))
    ward = wards(:demo)
    ana = ward.people.create!(given_name: "Anabel", avatar_key: "gato", favorite_year: 2021)
    QuizRun.create!(
      device_digest: "liga-type-ana",
      person: ana,
      pack_id: "coronas",
      position: 10,
      score: 42,
      status: "finished",
      opened_at: Time.current
    )
    visit street_leaderboard_path(view: "full")
    assert_selector "[data-controller~='liga-search']"
    assert_selector ".liga-court-row", text: /Carmen/
    find("#leaderboard_q").set("Ana")
    assert_no_selector ".liga-court-row", text: /Carmen/, wait: 6
    assert_selector ".liga-court-row", text: /Anabel/
    assert_no_selector ".liga-court-podium"
    assert_includes page.current_url, "q=Ana"
    assert_equal "leaderboard_q", page.evaluate_script("document.activeElement && document.activeElement.id")
    find("#leaderboard_q").send_keys(:escape)
    assert_selector ".liga-court-row", text: /Carmen/, wait: 6
    assert_selector ".liga-full-panel"
    assert_no_match(/[?&]q=/, page.current_url)
  end

  test "hub rank up ring on player card" do
    set_system_viewport(390, 844)
    sign_in_fixture_person_direct!(people(:pili))
    visit root_path(rank_up: 1)
    assert_selector ".quiz-hud.is-rank-up"
    sleep 0.6
    shot("rank-up-phone")
  end

  test "hub pack unlock animation" do
    set_system_viewport(390, 844)
    sign_in_fixture_person_direct!(people(:pili))
    next_pack = QuizDefinition.catalog.pack_ids.second
    visit street_map_path(unlock: next_pack)
    assert_selector "#pack-#{next_pack}[data-street-motion-sequence-value='packUnlock']"
    sleep 0.5
    shot("hub-pack-unlock-phone")
  end

  test "pack ceremony on last question" do
    set_quiz_viewport(390, 844)
    QuizRun.where(status: "open").update_all(status: "finished")
    sign_in_fixture_person_direct!(people(:pili))
    find(".street-map-door-play").click
    assert_selector "#street_quiz"
    run = QuizRun.open_runs.order(:id).last
    pack = QuizDefinition.catalog.find_pack(run.pack_id)
    seed_ceremony_board!(run.pack_id)
    question = pack.question_at(10)
    pack.questions.first(9).each do |answered|
      run.quiz_answers.create!(
        device_digest: run.device_digest,
        pack_id: run.pack_id,
        question_id: answered.id,
        choice_key: answered.correct_choice,
        correct: true
      )
    end
    run.update!(position: 10, score: pack.questions.first(9).sum(&:points), ends_at: nil)
    Quizzes::Submit.call(run: run.reload, choice_key: question.correct_choice)
    visit jugar_path
    assert_selector ".quiz-board.is-settled"
    click_button I18n.t("quiz.results")
    assert_selector "#street_quiz.is-overlay.is-ceremony"
    assert_selector "#street_quiz[data-street-motion-sequence-value='packComplete']"
    assert_selector ".street-ceremony-stat", count: 4
    assert_selector ".street-ceremony-stat .street-ceremony-streak-icon[src*='living-fire-hud-v1.webp']", count: 1
    assert_selector ".score-fly[data-from='50'][data-final='89']"
    assert_selector ".street-ceremony-score-math strong", text: "+39"
    assert_selector ".street-ceremony-score-math", text: /50\s*\+39/
    assert_selector ".street-ceremony-score-label", text: /#{Regexp.escape(I18n.t("street.ceremony_score_label"))}/i
    assert_selector ".street-ceremony-crowns", text: /#{Regexp.escape(I18n.t("chrome.crowns_word"))}/i
    assert_selector ".street-ceremony-shout", text: /#{Regexp.escape(I18n.t("street.ceremony_verdict.performance.perfect.title"))}/i
    assert_no_text "Incredible"
    assert_no_text "Increíble"
    assert_no_text "Incroyable"
    assert_ceremony_temple_scrim
    sleep 2.5
    find(".street-ceremony-chest-wrap").click
    assert_selector ".street-ceremony-chest.is-opening"
    assert_selector ".street-ceremony-spark", minimum: 8, visible: :all
    wait_for_brush_fonts!
    assert_ceremony_breakpoints!
  end

  test "challenge button on pack ceremony" do
    set_quiz_viewport(390, 844)
    sign_in_fixture_person_direct!(people(:pili))
    QuizRun.where(status: "open").update_all(status: "finished")
    visit root_path
    find(".street-map-door-play").click
    assert_selector "#street_quiz"
    run = QuizRun.open_runs.order(:id).last
    assert run, "expected open quiz run after starting pack"
    seed_ceremony_board!(run.pack_id)
    pack = QuizDefinition.catalog.find_pack(run.pack_id)
    question = pack.question_at(10)
    run.update!(position: 10, score: 80, ends_at: nil)
    Quizzes::Submit.call(run: run.reload, choice_key: question.correct_choice)
    visit jugar_path
    assert_selector ".quiz-board.is-settled"
    click_button I18n.t("quiz.next")
    assert_selector "#street_quiz.is-overlay.is-ceremony"
    assert_selector ".street-ceremony-boards"
    assert_selector ".street-challenge-btn"
    sleep 2.5
    wait_for_brush_fonts!
    assert_in_viewport ".street-challenge-btn", slop: 48
    shot("ceremony-challenge-phone")
  end

  test "duel ceremony shows a named winner and a readable faceoff" do
    friend = open_duel_ceremony_result!(friend_score: 150)

    assert_selector "#street_quiz.is-overlay.is-ceremony[data-quiz-theme='dark'][data-quiz-atmosphere='dramatic']"
    assert_selector ".duel-ceremony-world.is-duel-rematch picture img[src*='campus-duel-rematch-storm-v1']"
    assert_selector ".street-ceremony-shout", text: /#{Regexp.escape(I18n.t("street.ceremony_verdict.duel.behind.title", locale: :fr, name: friend.given_name))}/i
    assert_selector ".street-ceremony-kicker", text: /Ton score : \d+ couronnes\. Écart à combler : \d+ couronnes\./
    assert_selector ".duel-ceremony-impact > header h2", text: I18n.t("duel_campus.outcomes.behind", locale: :fr, name: friend.given_name)
    assert_selector ".duel-ceremony-score-side.is-me", text: /#{Regexp.escape(I18n.t("duel_campus.ceremony.you", locale: :fr))}\s*\d+\s*#{Regexp.escape(I18n.t("chrome.crowns_word", locale: :fr))}/i
    assert_selector ".duel-ceremony-versus-mark", text: /#{Regexp.escape(I18n.t("duel_campus.ceremony.versus", locale: :fr))}/i
    assert_selector ".duel-ceremony-score-side.is-friend.is-winner", text: /#{friend.given_name}\s*150\s*#{Regexp.escape(I18n.t("chrome.crowns_word", locale: :fr))}/i
    assert_selector ".duel-ceremony-impact > .btn", text: I18n.t("duel_campus.ceremony.actions.behind", locale: :fr)
    assert_no_text I18n.t("duel_campus.ceremony.title", locale: :fr)
    capture_duel_ceremony_breakpoints("rematch")
  end

  test "duel victory ceremony celebrates the player in Celestial Light" do
    friend = open_duel_ceremony_result!(friend_score: 40)

    assert_selector "#street_quiz.is-overlay.is-ceremony[data-quiz-theme='light'][data-quiz-atmosphere='glorious']"
    assert_selector ".duel-ceremony-world.is-duel-victory picture img[src*='campus-duel-victory-friends-v1']"
    assert_selector ".street-ceremony-shout", text: /#{Regexp.escape(I18n.t("street.ceremony_verdict.duel.ahead.title", locale: :fr, name: friend.given_name))}/i
    assert_selector ".street-ceremony-kicker", text: /\d+ couronnes : tu prends l’avantage\./
    assert_selector ".duel-ceremony-impact > header h2", text: I18n.t("duel_campus.outcomes.ahead", locale: :fr, name: friend.given_name)
    assert_selector ".duel-ceremony-score-side.is-me.is-winner"
    assert_selector ".duel-ceremony-score-side.is-friend", text: /#{friend.given_name}\s*40\s*#{Regexp.escape(I18n.t("chrome.crowns_word", locale: :fr))}/i
    assert_selector ".duel-ceremony-impact > .btn", text: I18n.t("duel_campus.ceremony.actions.ahead", locale: :fr)
    capture_duel_ceremony_breakpoints("victory")
  end

  test "street next ignores a double activation" do
    set_quiz_viewport(390, 844)
    ready_street_quiz!
    correct = find("#street_quiz")["data-quiz-correct-value"]
    page.all(".choice-btn").find { |button| button["data-choice-key"] == correct }.click
    assert_selector ".quiz-board.is-settled"

    page.execute_script(<<~JS)
      var next = document.querySelector("#street_quiz .quiz-next");
      next.click();
      next.click();
    JS

    assert_selector ".choice-btn"
    assert_equal 2, QuizRun.order(:id).last.reload.position
  end

  test "street quiz sheet type miss ticks and swipe" do
    set_quiz_viewport(390, 844)
    ready_street_quiz!
    assert_selector "#street_quiz[data-controller~=quiz]"
    assert_no_selector "#street_quiz[data-controller~=story]"
    assert_selector "#street_quiz.is-overlay"
    assert_no_selector ".story-ticks"
    assert_no_selector ".story-close"
    assert_selector ".quiz-sheet"
    assert_selector ".street-quiz-apex"
    assert_apex_above_sheet!
    assert_selector ".quiz-kicker"
    assert_no_selector "#street_quiz .choice-mark"
    assert_selector ".street-score span", text: "0"
    assert_no_selector "#street_quiz .btn.btn-gold"
    assert_operator score_top, :>, 0
    assert_operator score_top, :<, 0.35
    peek = sheet_top
    assert_operator peek, :>=, 0.42
    visible = visible_choice_count
    assert_operator visible, :>=, 2
    pair("01-ask")

    wrong = page.all(".choice-btn").find { |btn| btn["data-choice-key"] != find("#street_quiz")["data-quiz-correct-value"] }
    wrong.click
    assert_selector ".quiz-board.is-wrong"
    assert_apex_above_sheet!
    assert_selector ".quiz-bar.is-correct.is-right"
    assert_selector ".quiz-bar.is-wrong.is-miss"
    assert_selector ".quiz-bar.is-correct .quiz-flag.is-yes .picto-tick"
    assert_selector ".quiz-bar.is-wrong.is-miss .quiz-flag.is-no .picto-cross"
    assert_selector "a.quiz-scripture .quiz-read", text: I18n.t("quiz.read")
    assert_selector "a.quiz-scripture .quiz-cite", text: QuizRun.order(:id).last.question.scripture.cite
    assert_no_text I18n.t("quiz.read_more")
    assert_selector ".quiz-sheet"
    assert_selector ".street-score span", text: "0"
    assert_no_selector ".street-score.is-tick"
    assert_selector ".street-praise.is-miss", text: I18n.t("quiz.almost")
    assert_no_selector ".quiz-shout"
    pair("02-miss")
    assert_settled_choice_row! page.first(".quiz-bar")
    assert_settled_choice_row! page.first(".quiz-bar.is-correct")

    click_button I18n.t("quiz.next")
    assert_selector ".choice-btn"
    assert_selector ".quiz-sheet"
    assert_selector ".street-score span", text: "0"
    assert_no_selector "#street_quiz .btn.btn-gold"
    pair("02b-next-ask")
    right = page.all(".choice-btn").find { |btn| btn["data-choice-key"] == find("#street_quiz")["data-quiz-correct-value"] }
    right.click
    assert_selector ".quiz-board.is-settled"
    assert_selector ".quiz-sheet"
    assert_selector ".street-score"
    assert_selector ".street-praise"
    run = QuizRun.order(:id).last
    shout = ApplicationController.helpers.street_praise_line(run, run.question)
    assert_selector ".street-praise-line", text: shout
    assert_praise_inside_shot(shout)
    pair("03-right")

    swipe("#street_quiz .play-shot", dx: 160, dy: 0)
    assert_selector ".quiz-progress", text: /1 \/ 10/
    assert_selector ".quiz-board.is-settled"
    pair("04-swipe-back")

    swipe("#street_quiz .play-shot", dx: -160, dy: 0)
    assert_selector ".quiz-progress", text: /2 \/ 10/
    pair("05-swipe-next")

    click_button I18n.t("quiz.next")
    assert_selector ".choice-btn"
    first(".choice-btn").click
    click_button I18n.t("quiz.next")
    assert_selector "#street_quiz[data-stage-timer-end-value]"
    assert_selector "#street_quiz[data-stage-timer-duration-value]"
    duration = find("#street_quiz")["data-stage-timer-duration-value"].to_i
    assert_operator duration, :>, 0
    assert_no_selector ".play-timer.is-warn"
    assert_no_selector ".play-timer.is-low"
    assert_no_selector "#street_quiz.is-timer-warn"
    assert_no_selector "#street_quiz.is-timer-hot"
    pair("06-timed")
  end

  test "settled four bars keep next on the still" do
    set_quiz_viewport(390, 844)
    ready_street_quiz!
    run = QuizRun.order(:id).last
    question = QuizDefinition.catalog.find_pack("coronas").question_at(2)
    run.update!(pack_id: "coronas", position: 2, score: 0, ends_at: nil, status: "open")
    visit jugar_path

    wrong = page.all(".choice-btn").find { |btn| btn["data-choice-key"] != question.correct_choice }
    wrong.click
    assert_selector ".quiz-board.is-settled"
    assert_selector ".quiz-bar", count: 4
    assert_selector ".quiz-bar .quiz-flag", count: 4
    assert_selector ".quiz-bar.is-correct .quiz-flag.is-yes .picto-tick", count: 1
    assert_selector ".quiz-bar:not(.is-correct) .quiz-flag.is-no .picto-cross", count: 3
    assert_settled_choice_row! page.first(".quiz-bar")
    assert_settled_choice_row! page.first(".quiz-bar.is-correct")
    assert_selector ".play-shot .street-shot-actions .quiz-next"
    assert_selector ".play-shot a.quiz-scripture"
    assert_in_viewport ".play-shot .street-shot-actions .quiz-next"
    assert_no_selector ".street-quiz-dock"
    assert_no_selector ".quiz-board .quiz-next"
    assert_no_selector ".quiz-board .quiz-scripture"
    shot("07-four-bars-settled")
  end

  def seed_ceremony_board!(pack_id)
    ward = wards(:demo)
    [
      [ people(:pili), 102 ],
      [ people(:carmen_garcia), 95 ],
      [ people(:carmen_lopez), 87 ]
    ].each do |person, score|
      run = QuizRun.find_or_initialize_by(person_id: person.id, pack_id:)
      next if run.persisted? && run.open?

      run.device_digest ||= GameSession.digest_token("ceremony-board-#{person.id}")
      run.position = 10
      run.score = score
      run.status = "finished"
      run.opened_at ||= Time.current
      run.save!
    end
    lucia = Person.find_or_initialize_by(ward:, given_name_key: "lucia", family_name_key: "soto")
    lucia.assign_attributes(
      given_name: "Lucía",
      family_name: "Soto",
      avatar_key: "loro",
      favorite_year: 2009
    )
    lucia.save!
    return if QuizRun.exists?(person_id: lucia.id, pack_id:)

    QuizRun.create!(
      person: lucia,
      pack_id:,
      device_digest: GameSession.digest_token("ceremony-board-lucia"),
      position: 10,
      score: 76,
      status: "finished",
      opened_at: Time.current
    )
  end

  test "street praise stays inside the still" do
    set_system_viewport(390, 844)
    ready_street_quiz!
    right = page.all(".choice-btn").find { |btn| btn["data-choice-key"] == find("#street_quiz")["data-quiz-correct-value"] }
    right.click
    assert_selector ".street-praise-line"
    assert_praise_inside_shot
    %w[Spectaculaire ! Excellentissime ! Spectacular! ¡Espectacular!].each do |line|
      assert_praise_inside_shot(line)
    end
    set_system_viewport(768, 1024)
    assert_praise_inside_shot("Spectaculaire !")
    set_system_viewport(1280, 800)
    assert_praise_inside_shot("Spectaculaire !")
  end

  test "correct answer performance raises one living fire in light and dark" do
    set_quiz_viewport(390, 844)
    ready_street_quiz!
    run = QuizRun.open_runs.where(person: people(:pili)).order(:id).last

    4.times do
      right = page.all(".choice-btn").find { |btn| btn["data-choice-key"] == find("#street_quiz")["data-quiz-correct-value"] }
      right.click
      assert_selector "#street_quiz.is-actions-ready"
      click_button I18n.t("quiz.next")
      assert_selector ".choice-btn"
    end
    right = page.all(".choice-btn").find { |btn| btn["data-choice-key"] == find("#street_quiz")["data-quiz-correct-value"] }
    right.click
    assert_selector "#street_quiz.is-actions-ready .street-hit-performance[data-streak-count='5']"
    assert_selector ".quiz-hud-streak[data-tier='blaze'] img.quiz-hud-streak-icon[src*='living-fire-hud-v1.webp']", count: 1
    assert_selector ".street-hit-value.is-gain", text: "+10"
    assert_selector ".street-hit-poster[src*='living-fire-poster-v1.webp']", count: 1
    assert_selector ".street-hit-video", count: 1, visible: true
    assert_selector ".street-hit-video source[src*='living-fire-loop-v1.webm']", count: 1, visible: :all
    assert_selector ".street-hit-next.is-max", text: /#{Regexp.escape(I18n.t("quiz.bonus_max_active", bonus: 5))}/i
    assert_no_selector ".street-hit-performance .picto-fire"

    run.reload
    image = run.question.presentation&.[]("image").to_s
    chrome_rows = Quizzes::Chrome.stills.deep_dup

    {
      "light" => [ [ 390, 844 ], [ 768, 1024 ], [ 1440, 900 ] ],
      "dark" => [ [ 390, 844 ], [ 768, 1024 ], [ 1440, 900 ] ]
    }.each do |theme, viewports|
      Quizzes::Chrome.stills = chrome_rows.merge(image => chrome_rows.fetch(image, {}).merge("mode" => theme))
      visit jugar_path
      assert_selector "#street_quiz[data-quiz-theme=#{theme}] .street-hit-performance[data-streak-count='5']"
      assert_selector ".street-hit-poster", count: 1
      assert_selector ".street-hit-video", count: 1, visible: :all
      assert_selector "#street_quiz.is-actions-ready"
      viewports.each do |width, height|
        set_quiz_viewport(width, height)
        assert_jugar_chrome_on_column
        assert_hit_performance_geometry!
        shot("jugar-performance-#{theme}-#{width}x#{height}")
      end
    end

    assert_empty page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
  ensure
    Quizzes::Chrome.reset!
    set_quiz_viewport(390, 844) if self.class.chrome_binary
  end

  test "a broken streak visibly calms its living fire and invites a restart" do
    set_quiz_viewport(390, 844)
    ready_street_quiz!
    run = QuizRun.open_runs.where(person: people(:pili)).order(:id).last
    5.times do |index|
      right = page.all(".choice-btn").find { |btn| btn["data-choice-key"] == find("#street_quiz")["data-quiz-correct-value"] }
      right.click
      assert_selector "#street_quiz.is-actions-ready .street-hit-performance[data-streak-count='#{index + 1}']"
      click_button I18n.t("quiz.next")
      assert_selector "#street_quiz[data-quiz-streak-value='#{index + 1}'] .choice-btn"
    end
    wrong = page.all(".choice-btn").find { |btn| btn["data-choice-key"] != find("#street_quiz")["data-quiz-correct-value"] }
    wrong.click
    assert_selector "#street_quiz[data-stage-sfx-value=street_wrong_soft] .street-hit-performance.is-break[data-streak-count='0']"
    assert_selector ".quiz-hud-streak.is-break img.quiz-hud-streak-icon[src*='living-fire-dormant-hud-v1.webp']", count: 1
    assert_selector ".street-hit-performance.is-break .street-hit-poster[src*='living-fire-dormant-v1.webp']", count: 1
    assert_selector ".street-hit-performance.is-break .street-hit-video", count: 1, visible: true
    assert_selector ".street-hit-performance.is-break .street-hit-video source[src*='living-fire-break-v1.webm']", count: 1, visible: :all
    assert_selector ".street-hit-breakdown.is-lost", text: /#{Regexp.escape(I18n.t("quiz.bonus_lost", count: 5))}/i
    assert_selector ".street-hit-next", text: /#{Regexp.escape(I18n.t("quiz.streak_restart"))}/i

    run.reload
    image = run.question.presentation&.[]("image").to_s
    chrome_rows = Quizzes::Chrome.stills.deep_dup
    {
      "light" => [ [ 390, 844 ], [ 768, 1024 ], [ 1440, 900 ] ],
      "dark" => [ [ 390, 844 ], [ 768, 1024 ], [ 1440, 900 ] ]
    }.each do |theme, viewports|
      Quizzes::Chrome.stills = chrome_rows.merge(image => chrome_rows.fetch(image, {}).merge("mode" => theme))
      visit jugar_path
      assert_selector "#street_quiz[data-quiz-theme=#{theme}].is-actions-ready .street-hit-performance.is-break"
      viewports.each do |width, height|
        set_quiz_viewport(width, height)
        wait_for_image!("#street_quiz .challenge-story")
        assert_hit_performance_geometry!
        shot("jugar-streak-break-#{theme}-#{width}x#{height}")
      end
    end

    set_quiz_viewport(390, 844)
    click_button I18n.t("quiz.next")
    assert_selector "#street_quiz[data-quiz-streak-value='0'] .choice-btn"
    rebuilt = page.all(".choice-btn").find { |btn| btn["data-choice-key"] == find("#street_quiz")["data-quiz-correct-value"] }
    rebuilt.click
    assert_selector "#street_quiz[data-stage-sfx-value=correct_gold].is-actions-ready .street-hit-performance:not(.is-break)[data-streak-count='1']"
    assert_selector ".street-hit-poster[src*='living-fire-poster-v1.webp']", count: 1
    assert_selector ".street-hit-video", count: 1, visible: true
    assert_selector ".street-hit-video source[src*='living-fire-loop-v1.webm']", count: 1, visible: :all

    assert_empty page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
  ensure
    Quizzes::Chrome.reset!
    set_quiz_viewport(390, 844) if self.class.chrome_binary
  end

  def ready_street_quiz!
    sign_in_fixture_person_direct!(people(:pili))
    find(".street-map-door-play").click if page.has_css?(".street-map-door-play", wait: 1)
    assert_selector "#street_quiz.play-reel.is-quiz.is-street"
  end

  def assert_duel_race_geometry!
    geometry = page.evaluate_script(<<~JS)
      (function() {
        var hud = document.querySelector('#street_quiz .quiz-hud').getBoundingClientRect();
        var rail = document.querySelector('#street_quiz .duel-quiz-rail-main').getBoundingClientRect();
        var timer = document.querySelector('#street_quiz .quiz-timer-slot .play-timer').getBoundingClientRect();
        var sheet = document.querySelector('#street_quiz .quiz-sheet').getBoundingClientRect();
        return {
          hudBottom: hud.bottom,
          railTop: rail.top,
          railBottom: rail.bottom,
          railLeft: rail.left,
          railRight: rail.right,
          timerTop: timer.top,
          timerBottom: timer.bottom,
          timerLeft: timer.left,
          timerRight: timer.right,
          sheetTop: sheet.top,
          viewportWidth: window.innerWidth,
          railTransform: getComputedStyle(document.querySelector('#street_quiz .duel-quiz-rail')).transform,
          railAnimation: getComputedStyle(document.querySelector('#street_quiz .duel-quiz-rail')).animationName,
          railClass: document.querySelector('#street_quiz .duel-quiz-rail').className,
          railPosition: getComputedStyle(document.querySelector('#street_quiz .duel-quiz-rail')).position,
          slotTransform: getComputedStyle(document.querySelector('#street_quiz .duel-quiz-race-slot')).transform,
          slotWidth: document.querySelector('#street_quiz .duel-quiz-race-slot').getBoundingClientRect().width
        };
      })()
    JS
    assert_operator geometry["railTop"], :>=, geometry["hudBottom"] - 2
    assert_operator geometry["railBottom"], :<, geometry["timerTop"]
    assert_operator geometry["timerBottom"], :<=, geometry["sheetTop"]
    assert_operator geometry["railLeft"], :>=, 4
    assert_operator geometry["railRight"], :<=, geometry["viewportWidth"] - 4, geometry.inspect
    assert_operator geometry["timerLeft"], :>=, 4
    assert_operator geometry["timerRight"], :<=, geometry["viewportWidth"] - 4, geometry.inspect
  end

  def duel_race_dimensions
    page.evaluate_script(<<~JS)
      (function() {
        var rail = document.querySelector('#street_quiz .duel-quiz-rail-main').getBoundingClientRect();
        return { width: rail.width, height: rail.height };
      })()
    JS
  end

  def assert_hit_performance_geometry!
    geometry = page.evaluate_script(<<~JS)
      (function() {
        var quiz = document.querySelector('#street_quiz').getBoundingClientRect();
        var line = document.querySelector('.street-praise-line').getBoundingClientRect();
        var performance = document.querySelector('.street-hit-performance').getBoundingClientRect();
        var actions = document.querySelector('.street-shot-actions').getBoundingClientRect();
        var media = document.querySelector('.street-hit-media').getBoundingClientRect();
        var poster = document.querySelector('.street-hit-poster').getBoundingClientRect();
        var ledger = document.querySelector('.street-hit-ledger').getBoundingClientRect();
        return {
          quizLeft: quiz.left,
          quizRight: quiz.right,
          lineBottom: line.bottom,
          performanceTop: performance.top,
          performanceBottom: performance.bottom,
          performanceLeft: performance.left,
          performanceRight: performance.right,
          actionsTop: actions.top,
          mediaWidth: media.width,
          mediaHeight: media.height,
          mediaRight: media.right,
          posterWidth: poster.width,
          posterHeight: poster.height,
          ledgerLeft: ledger.left,
          viewportWidth: window.innerWidth
        };
      })()
    JS

    assert_operator geometry["performanceTop"], :>=, geometry["lineBottom"] - 2
    assert_operator geometry["performanceBottom"], :<, geometry["actionsTop"]
    assert_operator geometry["performanceLeft"], :>=, geometry["quizLeft"] - 1
    assert_operator geometry["performanceRight"], :<=, geometry["quizRight"] + 1
    assert_in_delta geometry["mediaWidth"], geometry["mediaHeight"], 2
    assert_in_delta geometry["posterWidth"], geometry["posterHeight"], 2
    assert_operator geometry["ledgerLeft"], :>=, geometry["mediaRight"] - 2
    assert_no_horizontal_layout_overflow
  end

  def clear_street_session!
    page.driver.browser.manage.delete_all_cookies
  end

  def sign_in_fixture_person_direct!(person)
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.post enter_ward_path, params: { code: person.ward.code }
    session.post street_profile_path, params: { person_id: person.id, favorite_year: person.favorite_year }

    clear_street_session!
    visit root_path
    session.cookies.to_hash.each do |name, value|
      page.driver.browser.manage.add_cookie(name:, value:, path: "/")
    end
    visit root_path
  end

  def open_duel_ceremony_result!(friend_score:)
    pili = people(:pili)
    friend = wards(:demo).people.create!(given_name: "Amina", avatar_key: "aguila", favorite_year: 2003)
    friend_run = QuizRun.create!(
      device_digest: "duel-ceremony-visual-#{friend_score}", person: friend, pack_id: "placas",
      position: 10, score: friend_score, status: "finished", opened_at: 1.hour.ago
    )
    invitation = DuelInvitation.create!(
      challenger_person: friend, recipient_person: pili,
      challenger_run: friend_run, challenger_score: friend_run.score,
      token_digest: SecureRandom.hex(32), status: "open", expires_at: 7.days.from_now
    )
    Quizzes::DuelInvitationClaim.call(invitation:, person: pili)

    set_quiz_viewport(390, 844)
    sign_in_fixture_person_direct!(pili)
    page.driver.browser.manage.add_cookie(name: Locale::COOKIE.to_s, value: "fr", path: "/")
    QuizRun.where(person: pili, status: "open").update_all(status: "finished")
    visit root_path
    find(".street-map-door-play").click
    answer_action = find(".choice-btn", match: :first).find(:xpath, "ancestor::form")[:action]
    run = QuizRun.find(answer_action.match(%r{/quiz/(\d+)/answers})[1])
    pack = QuizDefinition.catalog.find_pack(run.pack_id)
    question = pack.question_at(10)
    pack.questions.first(9).each_with_index do |answered, index|
      correct = index < 7
      choice_key = if correct
        answered.correct_choice
      else
        answered.choices.map { |choice| choice["key"].to_s }.find { |key| key != answered.correct_choice }
      end
      run.quiz_answers.create!(
        device_digest: run.device_digest,
        pack_id: run.pack_id,
        question_id: answered.id,
        choice_key:,
        correct:,
        duration_ms: 5_700
      )
    end
    run.update!(position: 10, score: 66, ends_at: nil)
    Quizzes::Submit.call(run: run.reload, choice_key: question.correct_choice)
    run.quiz_answers.update_all(duration_ms: 5_700)
    visit jugar_path
    click_button I18n.t("quiz.next", locale: :fr)
    friend
  end

  def capture_duel_ceremony_breakpoints(outcome)
    sleep 2.5
    [
      [ 390, 844, "duel-ceremony-#{outcome}-390x844" ],
      [ 768, 1024, "duel-ceremony-#{outcome}-768x1024" ],
      [ 1440, 900, "duel-ceremony-#{outcome}-1440x900" ]
    ].each do |width, height, name|
      set_quiz_viewport(width, height)
      page.execute_script("document.querySelector('.street-ceremony-scroll')?.scrollTo(0, 0)")
      sleep 0.35
      assert_no_horizontal_layout_overflow
      shot(name)
      page.execute_script("document.querySelector('.duel-ceremony-impact')?.scrollIntoView({ block: 'center' })")
      assert_no_horizontal_layout_overflow
    end
    assert_empty page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
  end

  def seed_liga_window_rows!(total:)
    ward = wards(:demo)
    stake_wards = Quizzes::StakeScope.wards_for(ward:)
    existing = Quizzes::Leaderboard.pack_best_totals(wards: stake_wards).size
    needed = [ total - existing, 0 ].max
    now = Time.current
    rows = Array.new(needed) do |index|
      name = "Fenetre#{index.to_s.rjust(4, "0")}"
      {
        ward_id: ward.id,
        given_name: name,
        given_name_key: Person.name_key(name),
        family_name_key: "",
        avatar_key: Player::AVATARS[index % Player::AVATARS.size],
        favorite_year: 1900 + (index % 100),
        locale: "fr",
        created_at: now,
        updated_at: now
      }
    end
    Person.insert_all!(rows) if rows.any?
    ids = ward.people.where("given_name LIKE ?", "Fenetre%").order(:id).pluck(:id)
    QuizRun.insert_all!(ids.each_with_index.map do |person_id, index|
      {
        person_id:,
        device_digest: "liga-window-#{index}",
        pack_id: "coronas",
        position: 10,
        score: 10_000 - index,
        status: "finished",
        opened_at: now,
        created_at: now,
        updated_at: now
      }
    end)
    @liga_last_name = "Fenetre#{(needed - 1).to_s.rjust(4, "0")}"
  end

  def assert_liga_touch_targets!
    sizes = page.evaluate_script(<<~JS)
      (function() {
        return [
          document.querySelector('.liga-court-search-open'),
          document.querySelector('.liga-rivalry-cta'),
          document.querySelector('.liga-around .liga-court-row-button'),
          document.querySelector('.liga-see-all')
        ].filter(Boolean).map(function(element) {
          var rect = element.getBoundingClientRect();
          return { width: rect.width, height: rect.height };
        });
      })()
    JS
    assert sizes.all? { |size| size["width"] >= 44 && size["height"] >= 44 }, sizes.inspect
  end

  def assert_in_viewport(selector, slop: 8)
    visible = page.evaluate_script(<<~JS)
      (function() {
        var el = document.querySelector(#{selector.to_json});
        if (!el) return false;
        var r = el.getBoundingClientRect();
        return r.top >= -8 && r.bottom <= (window.innerHeight + #{slop.to_i}) && r.height > 0;
      })()
    JS
    assert visible, "#{selector} should sit in the first screen"
  end

  def assert_ceremony_title_clears_hud
    gap = page.evaluate_script(<<~JS)
      (function() {
        var hud = document.querySelector("#street_quiz.is-ceremony .quiz-hud");
        var shout = document.querySelector(".street-ceremony-shout");
        if (!hud || !shout) return null;
        return shout.getBoundingClientRect().top - hud.getBoundingClientRect().bottom;
      })()
    JS
    assert gap, "ceremony shout should be measurable against the HUD"
    assert_operator gap.to_f, :>=, 32, "ceremony title should breathe under the HUD (got #{gap}px)"
  end

  def assert_ceremony_stack_on_column
    measured = page.evaluate_script(<<~JS)
      (function() {
        var quiz = document.querySelector("#street_quiz.is-ceremony");
        var hud = document.querySelector("#street_quiz.is-ceremony .quiz-hud");
        var stack = document.querySelector("#street_quiz.is-ceremony .street-ceremony");
        if (!quiz || !hud || !stack) return null;
        var root = parseFloat(getComputedStyle(document.documentElement).fontSize) || 16;
        var raw = getComputedStyle(document.documentElement).getPropertyValue("--street-play-col").trim();
        var q = quiz.getBoundingClientRect();
        var colPx = raw.endsWith("rem") ? parseFloat(raw) * root : q.width;
        var h = hud.getBoundingClientRect();
        var s = stack.getBoundingClientRect();
        var p = hud.querySelector(".quiz-hud-pack")?.getBoundingClientRect();
        var mid = (q.left + q.right) / 2;
        return {
          hudW: Math.round(h.width),
          stackW: Math.round(s.width),
          colPx: Math.round(Math.min(colPx, q.width - 24)),
          worldFullBleed: q.left <= 2 && q.right >= window.innerWidth - 2,
          hudCentered: Math.abs((h.left + h.right) / 2 - mid) < 20,
          stackCentered: Math.abs((s.left + s.right) / 2 - mid) < 20,
          packCentered: window.innerWidth < 720 || (p && Math.abs((p.left + p.right) / 2 - (h.left + h.right) / 2) < 12),
          hudFits: h.width <= Math.min(colPx, q.width) + 24
        };
      })()
    JS
    assert measured, "ceremony HUD and stack should be measurable"
    assert measured["worldFullBleed"], "ceremony artwork should fill the viewport, not the play column"
    assert measured["hudFits"], "ceremony HUD should pin to the play column (hud=#{measured["hudW"]} col=#{measured["colPx"]})"
    assert_in_delta measured["hudW"], measured["stackW"], 20
    assert measured["hudCentered"], "ceremony HUD should stay centered on the still"
    assert measured["stackCentered"], "ceremony stack should stay centered on the still"
    assert measured["packCentered"], "ceremony pack title should sit on the HUD's true visual center"
  end

  def assert_ceremony_scroll_top!
    page.execute_script(<<~JS)
      var sc = document.querySelector("#street_quiz.is-ceremony .street-ceremony-scroll");
      if (sc) sc.scrollTop = 0;
    JS
  end

  def assert_ceremony_breakpoints!
    assert_ceremony_scroll_top!
    assert_ceremony_title_clears_hud
    assert_ceremony_stack_on_column
    assert_jugar_chrome_on_column
    assert_in_viewport ".street-challenge-btn", slop: 48
    assert_in_viewport ".street-ceremony-share", slop: 72
    shot("ceremony-phone")
    [
      [ 768, 1024, "jugar-ceremony-ipad" ],
      [ 1280, 800, "jugar-ceremony-desktop" ],
      [ 1440, 900, "jugar-ceremony-1440" ],
      [ 1850, 1900, "jugar-ceremony-report-1850x1900" ],
      [ 1920, 1080, "jugar-ceremony-xl" ]
    ].each do |width, height, name|
      set_quiz_viewport(width, height)
      assert_ceremony_scroll_top!
      sleep 0.35
      assert_ceremony_title_clears_hud
      assert_ceremony_stack_on_column
      assert_jugar_chrome_on_column
      shot(name)
    end
    assert_empty page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
    set_quiz_viewport(390, 844)
  end

  def open_hub_map_from_dock
    find(".navigation-dock a[href='#{street_map_path}']").click
  end

  def assert_shared_menu_contract!(standard_mobile:)
    assert_selector "dialog.chrome-drawer[open] .home-menu-nav-hub"
    assert_no_selector ".hub-menu-profile .home-menu-row-caret"
    assert_selector ".home-menu-invite[href='#{street_challenges_path(anchor: "inviter")}']", text: I18n.t("hub_menu.invite_friend")
    assert_selector ".home-menu-row[href='#{street_leaderboard_path}']", text: I18n.t("hub_menu.leaderboard")
    assert_selector ".home-menu-row[href='#{study_program_path}']", text: I18n.t("study.title")
    assert_selector ".hub-menu-legal a", count: 3

    metrics = page.evaluate_script(<<~JS)
      (function() {
        var sheet = document.querySelector(".chrome-drawer-sheet");
        var close = document.querySelector(".chrome-drawer .is-drawer-close");
        var targets = Array.from(document.querySelectorAll(
          ".chrome-drawer a, .chrome-drawer button, .chrome-drawer summary"
        )).filter(function(element) {
          var style = getComputedStyle(element);
          return style.display !== "none" && style.visibility !== "hidden" && !element.hidden
            && element.getBoundingClientRect().height > 0;
        });
        return {
          clientHeight: sheet.clientHeight,
          scrollHeight: sheet.scrollHeight,
          closeTop: close.getBoundingClientRect().top,
          minTargetHeight: Math.min.apply(null, targets.map(function(element) {
            return element.getBoundingClientRect().height;
          }))
        };
      })()
    JS
    assert_operator metrics["minTargetHeight"], :>=, 44, "every visible menu action must keep a 44px touch target"
    assert_operator metrics["closeTop"], :<, 32, "the close control must stay at the top of the drawer"
    if standard_mobile
      assert_operator metrics["scrollHeight"], :<=, metrics["clientHeight"] + 1,
        "the complete menu should fit a standard 390x844 mobile viewport"
    end
  end

  def assert_no_horizontal_layout_overflow
    overflow = page.evaluate_script(<<~JS)
      (function() {
        var viewport = document.documentElement.clientWidth;
        var offenders = Array.from(document.querySelectorAll("body *")).filter(function(el) {
          if (el.matches(".skip, .ripple, [aria-hidden='true']")) return false;
          var style = getComputedStyle(el);
          if (style.position === "fixed" || style.visibility === "hidden" || style.display === "none") return false;
          var scrollParent = el.parentElement;
          while (scrollParent && scrollParent !== document.body) {
            var overflowX = getComputedStyle(scrollParent).overflowX;
            if (overflowX === "auto" || overflowX === "scroll") return false;
            scrollParent = scrollParent.parentElement;
          }
          var rect = el.getBoundingClientRect();
          return rect.width > 0 && (rect.left < -2 || rect.right > viewport + 2);
        });
        return offenders.slice(0, 8).map(function(el) {
          var rect = el.getBoundingClientRect();
          return (el.id ? "#" + el.id : el.className || el.tagName) + " [" + rect.left.toFixed(1) + ", " + rect.right.toFixed(1) + "]";
        });
      })()
    JS
    assert_empty overflow, "layout content must fit the viewport: #{overflow.join(', ')}"
  end

  def assert_hub_shell_pinned
    pinned = page.evaluate_script(<<~JS)
      (function() {
        var hud = document.querySelector(".home-menu.is-hud .quiz-hud") || document.querySelector("#street_world .quiz-hud");
        var burger = document.querySelector(".home-menu > .home-menu-btn");
        var dock = document.querySelector(".navigation-dock");
        var feed = document.querySelector(".street-hub-feed");
        if (!hud || !burger || !dock || !feed) return false;
        if (document.querySelector(".hub-mini")) return false;
        var overflow = getComputedStyle(feed).overflowY;
        var menu = hud.closest(".home-menu");
        var menuPos = menu ? getComputedStyle(menu).position : getComputedStyle(hud).position;
        var before = hud.getBoundingClientRect();
        var burgerBox = burger.getBoundingClientRect();
        var burgerInHud = burgerBox.left >= before.left - 6
          && burgerBox.right <= before.right + 6
          && burgerBox.top >= before.top - 6
          && burgerBox.bottom <= before.bottom + 6;
        var hero = document.querySelector(".hub-hero") || document.querySelector(".street-hub-feed .street-card.is-map-door");
        var heroBefore = hero ? hero.getBoundingClientRect().top : before.bottom + 8;
        var dockBefore = dock.getBoundingClientRect().top;
        feed.scrollTop = Math.min(feed.scrollHeight, 280);
        feed.dispatchEvent(new Event("scroll"));
        var after = hud.getBoundingClientRect();
        var dockAfter = dock.getBoundingClientRect().top;
        feed.scrollTop = 0;
        feed.dispatchEvent(new Event("scroll"));
        return (overflow === "auto" || overflow === "scroll")
          && menuPos === "fixed"
          && burgerInHud
          && before.height >= 44 && before.height <= 104
          && heroBefore >= before.bottom - 12
          && Math.abs(after.top - before.top) < 10
          && Math.abs(dockBefore - dockAfter) < 2;
      })()
    JS
    assert pinned, "quiz HUD capsule should stay compact with the hamburger in the slot while the hub feed scrolls"
  end

  def assert_hub_hud_polish!(centered_pack:)
    geometry = page.evaluate_script(<<~JS)
      (function() {
        var hud = document.querySelector(".home-menu.is-hud .quiz-hud");
        var pack = hud && hud.querySelector(".quiz-hud-pack");
        var stats = hud && hud.querySelector(".quiz-hud-stats");
        var slot = hud && hud.querySelector(".quiz-hud-menu");
        var button = document.querySelector(".home-menu.is-hud > .home-menu-btn");
        if (!hud || !pack || !stats || !slot || !button) return null;
        var icon = button.querySelector(".home-menu-icon .picto");
        var h = hud.getBoundingClientRect();
        var p = pack.getBoundingClientRect();
        var s = stats.getBoundingClientRect();
        var slotBox = slot.getBoundingClientRect();
        var b = button.getBoundingClientRect();
        return {
          packCenterDelta: Math.abs(((p.left + p.right) / 2) - ((h.left + h.right) / 2)),
          hudRadius: parseFloat(getComputedStyle(hud).borderTopLeftRadius),
          buttonWidth: b.width,
          buttonHeight: b.height,
          iconWidth: icon ? icon.getBoundingClientRect().width : 0,
          buttonSlotXDelta: Math.abs(((b.left + b.right) / 2) - ((slotBox.left + slotBox.right) / 2)),
          buttonSlotYDelta: Math.abs(((b.top + b.bottom) / 2) - ((slotBox.top + slotBox.bottom) / 2)),
          statsGap: b.left - s.right
        };
      })()
    JS
    assert geometry, "hub HUD geometry should be measurable"
    assert_in_delta 16, geometry["hudRadius"], 0.25, "hub HUD corners should stay structured instead of pill-shaped"
    assert_operator geometry["buttonWidth"], :>=, 44, "hamburger must expose a 44px touch target"
    assert_operator geometry["buttonHeight"], :>=, 44, "hamburger must expose a 44px touch target"
    assert_operator geometry["iconWidth"], :>=, 30, "hamburger glyph should read clearly inside its touch target"
    assert_operator geometry["buttonSlotXDelta"], :<=, 1.5, "hamburger should be centered in its reserved HUD slot"
    assert_operator geometry["buttonSlotYDelta"], :<=, 1.5, "hamburger should share the HUD vertical axis"
    assert_operator geometry["statsGap"], :>=, 4, "hamburger should not crowd the streak counter"
    if centered_pack
      assert_operator geometry["packCenterDelta"], :<=, 1.5, "pack progress should be centered on the HUD, not the leftover grid space"
    end
  end

  def assert_hub_league_on_cta
    assert_above_hub_dock ".street-league"
  end

  def assert_above_hub_dock(selector)
    visible = page.evaluate_script(<<~JS)
      (function() {
        var el = document.querySelector(#{selector.to_json});
        if (!el) return false;
        var r = el.getBoundingClientRect();
        var cta = document.querySelector(".navigation-dock") || document.querySelector(".street-pulse") || document.querySelector(".street-play-cta");
        var limit = cta ? cta.getBoundingClientRect().top : window.innerHeight;
        return r.top >= -8 && r.bottom <= (limit + 8) && r.height > 0;
      })()
    JS
    assert visible, "#{selector} should sit above JUGAR on the first fold"
  end

  def assert_layout_chrome_full_width
    measured = page.evaluate_script(<<~JS)
      (function() {
        var hud = document.querySelector("body > .home-menu.is-hud");
        var dock = document.querySelector("body > .navigation-dock");
        if (!hud || !dock) return null;
        var h = hud.getBoundingClientRect();
        var d = dock.getBoundingClientRect();
        var viewport = document.documentElement.clientWidth;
        return {
          viewport: viewport,
          hudW: h.width,
          dockW: d.width,
          hudLeft: h.left,
          dockLeft: d.left,
          hudPosition: getComputedStyle(hud).position,
          dockPosition: getComputedStyle(dock).position
        };
      })()
    JS
    assert measured, "the layout HUD and dock should both be present"
    assert_equal "fixed", measured["hudPosition"]
    assert_equal "fixed", measured["dockPosition"]
    assert_in_delta measured["viewport"], measured["hudW"], 2, "HUD should span the viewport"
    assert_in_delta measured["viewport"], measured["dockW"], 2, "dock should span the viewport"
    assert_in_delta 0, measured["hudLeft"], 2, "HUD should start at the viewport edge"
    assert_in_delta 0, measured["dockLeft"], 2, "dock should start at the viewport edge"
  end

  def assert_hud_theme_contract(expected_theme = nil)
    measured = page.evaluate_script(<<~JS)
      (function() {
        var menu = document.querySelector("body > .home-menu.is-hud");
        var hud = menu && menu.querySelector(".quiz-hud");
        if (!menu || !hud) return null;

        var parseColor = function(value) {
          var probe = document.createElement("span");
          probe.style.color = value;
          document.body.appendChild(probe);
          var resolved = getComputedStyle(probe).color;
          probe.remove();
          var parts = resolved.match(/[\\d.]+/g).map(Number);
          return { r: parts[0], g: parts[1], b: parts[2], a: parts[3] == null ? 1 : parts[3] };
        };
        var blend = function(color, under) {
          return {
            r: color.r * color.a + under * (1 - color.a),
            g: color.g * color.a + under * (1 - color.a),
            b: color.b * color.a + under * (1 - color.a)
          };
        };
        var luminance = function(color) {
          var channel = function(value) {
            value = value / 255;
            return value <= 0.04045 ? value / 12.92 : Math.pow((value + 0.055) / 1.055, 2.4);
          };
          return 0.2126 * channel(color.r) + 0.7152 * channel(color.g) + 0.0722 * channel(color.b);
        };
        var contrast = function(a, b) {
          var la = luminance(a);
          var lb = luminance(b);
          return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
        };
        var style = getComputedStyle(hud);
        var text = parseColor(style.color);
        var glass = parseColor(style.getPropertyValue("--quiz-glass").trim());

        return {
          menuTheme: menu.dataset.hudTheme,
          hudTheme: hud.dataset.hudTheme,
          onBlack: contrast(text, blend(glass, 0)),
          onWhite: contrast(text, blend(glass, 255))
        };
      })()
    JS

    assert measured, "the shared HUD must expose its theme and contrast tokens"
    mode = find("body", visible: :all)[:class][/\bis-celestial-(light|dark)\b/, 1]
    expected_theme ||= "celestial-#{mode}" if mode
    assert_includes Hud::BarComponent::THEMES, expected_theme
    assert_equal expected_theme, measured["menuTheme"]
    assert_equal expected_theme, measured["hudTheme"]
    assert_operator measured["onBlack"], :>=, 7.0, "#{expected_theme} HUD must remain AAA on a black artwork region"
    assert_operator measured["onWhite"], :>=, 7.0, "#{expected_theme} HUD must remain AAA on a white artwork region"
  end

  def assert_praise_inside_shot(shout = nil)
    if shout.present?
      page.execute_script(<<~JS, shout)
        var line = document.querySelector(".street-praise-line");
        if (line) line.textContent = arguments[0];
      JS
    end
    fit = page.evaluate_script(<<~JS)
      (function() {
        var shot = document.querySelector("#street_quiz .play-shot");
        var line = document.querySelector(".street-praise-line");
        if (!shot || !line) return null;
        var s = shot.getBoundingClientRect();
        var l = line.getBoundingClientRect();
        return {
          text: line.textContent,
          leftOk: l.left >= s.left - 1,
          rightOk: l.right <= s.right + 1,
          topOk: l.top >= s.top - 1,
          bottomOk: l.bottom <= s.bottom + 1,
          lineW: Math.round(l.width),
          shotW: Math.round(s.width)
        };
      })()
    JS
    assert fit, "praise line should be on the still"
    assert fit["leftOk"] && fit["rightOk"],
      "praise #{fit["text"].inspect} should stay in the still (line #{fit["lineW"]}px, shot #{fit["shotW"]}px)"
    assert fit["topOk"] && fit["bottomOk"],
      "praise #{fit["text"].inspect} should stay vertically in the still"
  end

  def assert_jugar_chrome_on_column
    sleep 0.6
    geometry = page.evaluate_script(<<~JS)
      (function() {
        var quiz = document.querySelector("#street_quiz");
        var hud = document.querySelector("#street_quiz .quiz-hud");
        var face = document.querySelector(".quiz-hud-avatar") || document.querySelector(".chrome-face");
        var who = hud && hud.querySelector(".quiz-hud-who");
        var level = hud && hud.querySelector(".quiz-hud-level");
        var pack = hud && hud.querySelector(".quiz-hud-pack");
        var burger = document.querySelector(".home-menu > .home-menu-btn");
        var slot = hud && hud.querySelector(".quiz-hud-menu");
        var icon = burger && burger.querySelector(".home-menu-icon .picto");
        var mute = document.querySelector(".chrome-tools .mute");
        var flag = document.querySelector(".chrome-tools .lang-switch");
        if (!quiz || !hud || !face || !who || !level || !pack || !burger || !slot || !icon) return null;
        var q = quiz.getBoundingClientRect();
        var h = hud.getBoundingClientRect();
        var f = face.getBoundingClientRect();
        var w = who.getBoundingClientRect();
        var l = level.getBoundingClientRect();
        var p = pack.getBoundingClientRect();
        var b = burger.getBoundingClientRect();
        var s = slot.getBoundingClientRect();
        var i = icon.getBoundingClientRect();
        var mid = (q.left + q.right) / 2;
        return {
          aligned: !mute && !flag && f.left >= q.left - 12 && b.right <= q.right + 12 && b.left > mid && f.right < mid && f.height > 0,
          radius: parseFloat(getComputedStyle(hud).borderTopLeftRadius),
          buttonWidth: b.width,
          buttonHeight: b.height,
          iconWidth: i.width,
          buttonTop: b.top,
          buttonBottom: b.bottom,
          slotTop: s.top,
          slotBottom: s.bottom,
          iconColor: getComputedStyle(icon).color,
          iconVisibility: getComputedStyle(icon).visibility,
          iconOpacity: getComputedStyle(icon).opacity,
          slotXDelta: Math.abs(((b.left + b.right) / 2) - ((s.left + s.right) / 2)),
          slotYDelta: Math.abs(((b.top + b.bottom) / 2) - ((s.top + s.bottom) / 2)),
          levelInsideWho: l.left >= w.left - 1 && l.right <= w.right + 1 && l.top >= w.top - 1 && l.bottom <= w.bottom + 1,
          packCenterDelta: Math.abs(((p.left + p.right) / 2) - ((h.left + h.right) / 2)),
          viewportWidth: window.innerWidth
        };
      })()
    JS
    assert geometry, "jugar HUD geometry should be measurable"
    assert geometry["aligned"], "jugar keeps avatar left and hamburger right on the phone arch; mute and flag stay in the drawer"
    assert_in_delta 16, geometry["radius"], 0.25, "all Street HUD variants should share the 16px silhouette"
    assert_operator geometry["buttonWidth"], :>=, 44, "jugar hamburger must expose a 44px touch target"
    assert_operator geometry["buttonHeight"], :>=, 44, "jugar hamburger must expose a 44px touch target"
    assert_operator geometry["iconWidth"], :>=, 30, "jugar hamburger glyph should match the Hub visual weight"
    assert_operator geometry["slotXDelta"], :<=, 1.5, "jugar hamburger should be centered in its reserved HUD slot: #{geometry.inspect}"
    assert_operator geometry["slotYDelta"], :<=, 1.5, "jugar hamburger should share the HUD vertical axis: #{geometry.inspect}"
    assert geometry["levelInsideWho"], "jugar level should stay attached to the player identity: #{geometry.inspect}"
    if geometry["viewportWidth"] >= 600
      assert_operator geometry["packCenterDelta"], :<=, 1.5, "jugar pack progress should sit on the capsule's true center: #{geometry.inspect}"
    end
  end

  def assert_street_hud_radius!(selector: ".home-menu.is-hud .quiz-hud")
    radius = page.evaluate_script(<<~JS)
      (function() {
        var hud = document.querySelector(#{selector.to_json});
        return hud ? parseFloat(getComputedStyle(hud).borderTopLeftRadius) : null;
      })()
    JS
    assert radius, "Street HUD radius should be measurable for #{selector}"
    assert_in_delta 16, radius, 0.25, "all Street HUD variants should share the 16px silhouette"
  end

  def assert_abuelo_type_floor
    sizes = page.evaluate_script(<<~JS)
      (function() {
        var root = parseFloat(getComputedStyle(document.documentElement).fontSize) || 16;
        var minPx = parseFloat(getComputedStyle(document.documentElement).getPropertyValue("--type-min")) * root;
        var read = function(sel) {
          var el = document.querySelector(sel);
          return el ? parseFloat(getComputedStyle(el).fontSize) : null;
        };
        return {
          minPx: minPx,
          pack: read(".street-map-door-pack"),
          banner: read(".quiz-hud-rank"),
          name: read(".quiz-hud-name")
        };
      })()
    JS
    assert sizes, "type floor metrics should be readable"
    floor = sizes["minPx"] - 0.6
    %w[pack banner name].each do |key|
      next unless sizes[key]
      assert sizes[key] >= floor, "#{key} font-size #{sizes[key]} should be ≥ type-min #{sizes["minPx"]}"
    end
  end

  def assert_ceremony_temple_scrim
    assert_selector "#street_quiz.is-overlay.is-ceremony"
    assert_selector ".quiz-hud"
    assert_selector ".street-ceremony-shout"
    assert_selector ".street-ceremony-medallion"
    assert_selector ".street-ceremony-stats"
    assert_ceremony_title_clears_hud
    assert_selector ".street-ceremony-boards"
    assert_selector ".street-ceremony-board-kicker", text: /#{Regexp.escape(I18n.t("street.ceremony_board_kicker"))}/i
    assert_selector ".street-ceremony-score-label"
    assert_selector ".street-ceremony-chest-img"
    assert_selector ".street-ceremony-best-score .picto-crown", minimum: 1
    assert_selector ".street-ceremony-map"
    assert_selector ".street-challenge-btn"
    assert_selector ".street-ceremony-share"
    assert_selector ".street-ceremony-best-row", minimum: 1
    geometry = page.evaluate_script(<<~JS)
      (function() {
        const boards = document.querySelector('.street-ceremony-boards').getBoundingClientRect()
        const board = document.querySelector('.street-ceremony-board').getBoundingClientRect()
        const rows = Array.from(document.querySelectorAll('.street-ceremony-best-row')).map((row) => row.getBoundingClientRect().height)
        return { boardsWidth: boards.width, boardWidth: board.width, rowFloor: Math.min.apply(Math, rows) }
      })()
    JS
    assert_in_delta geometry["boardsWidth"], geometry["boardWidth"], 1
    assert_operator geometry["rowFloor"], :>=, 44
    assert_no_selector ".street-ceremony-lockup"
    assert_no_selector ".street-ceremony-plinth"
    hall = page.evaluate_script(<<~JS)
      (function() {
        var el = document.querySelector("#street_quiz .challenge-story");
        if (!el) return "";
        return el.getAttribute("src") || "";
      })()
    JS
    assert_includes hall, "campus-ceremony-friends-v1", "ceremony world should use the social celebration artwork"
  end

  def pair(name)
    [
      [ 320, 568, "phone-small" ],
      [ 360, 640, "phone-short" ],
      [ 390, 844, "phone" ],
      [ 430, 932, "phone-tall" ],
      [ 768, 1024, "ipad" ],
      [ 844, 390, "landscape-short" ],
      [ 1024, 768, "desktop" ],
      [ 1440, 900, "xl" ]
    ].each do |width, height, suffix|
      set_quiz_viewport(width, height)
      sleep 0.3
      shot("#{name}-#{suffix}")
      assert_quiz_viewport_fit!(suffix)
    end
    set_quiz_viewport(390, 844)
  end

  def set_quiz_viewport(width, height)
    set_system_viewport(width, height)
  end

  def assert_quiz_viewport_fit!(viewport)
    geometry = page.evaluate_script(<<~JS)
      (function() {
        var selectors = [
          "#street_quiz .quiz-hud",
          "#street_quiz .quiz-sheet",
          "#street_quiz .play-timer",
          "#street_quiz .street-shot-actions",
          "#street_quiz .choice-btn",
          "#street_quiz .quiz-bar",
          "#street_quiz .quiz-scripture",
          "#street_quiz .quiz-next",
          "body.is-street-play .home-menu-btn"
        ];
        return selectors.flatMap(function(selector) {
          return Array.from(document.querySelectorAll(selector)).map(function(el) {
            var r = el.getBoundingClientRect();
            return {
              selector: selector,
              left: r.left,
              top: r.top,
              right: r.right,
              bottom: r.bottom,
              height: r.height
            };
          });
        });
      })()
    JS
    width = page.evaluate_script("window.innerWidth")
    height = page.evaluate_script("window.innerHeight")
    geometry.each do |box|
      assert_operator box["left"], :>=, -2, "#{viewport}: #{box["selector"]} clips left"
      assert_operator box["top"], :>=, -2, "#{viewport}: #{box["selector"]} clips top"
      assert_operator box["right"], :<=, width + 2, "#{viewport}: #{box["selector"]} clips right"
      assert_operator box["bottom"], :<=, height + 2, "#{viewport}: #{box["selector"]} clips bottom"
      if box["selector"].end_with?(".choice-btn", ".quiz-bar", ".quiz-scripture", ".quiz-next", ".home-menu-btn")
        assert_operator box["height"], :>=, 44, "#{viewport}: interactive target is too short"
      end
    end
  end

  def visible_choice_count
    page.evaluate_script(<<~JS)
      (function() {
        var btns = Array.from(document.querySelectorAll("#street_quiz .choice-btn"));
        var h = window.innerHeight;
        return btns.filter(function(el) {
          var r = el.getBoundingClientRect();
          return r.top >= -8 && r.bottom <= (h + 8) && r.height > 20;
        }).length;
      })()
    JS
  end

  def assert_settled_choice_row!(bar)
    geo = bar.evaluate_script(<<~JS)
      (function() {
        var word = this.querySelector(".word");
        var meta = this.querySelector(".quiz-meta");
        var flag = this.querySelector(".quiz-flag");
        var fill = this.querySelector(".quiz-fill");
        var style = getComputedStyle(this);
        return {
          flex: style.flexDirection,
          bar: this.clientWidth,
          height: this.clientHeight,
          word: word.clientWidth,
          wordTop: word.offsetTop,
          wordHeight: word.offsetHeight,
          wordLeft: word.offsetLeft,
          metaTop: meta.offsetTop,
          flagLeft: flag ? flag.offsetLeft : null,
          flagColor: flag ? getComputedStyle(flag).color : "",
          yes: !!(flag && flag.classList.contains("is-yes")),
          fillH: fill ? fill.offsetHeight : 0,
          wordColor: getComputedStyle(word).color,
          bg: style.backgroundColor
        };
      }).call(this)
    JS
    assert_equal "row", geo["flex"]
    assert geo["flagLeft"], "settled choice needs a left mark"
    assert_operator geo["flagLeft"], :<, geo["wordLeft"]
    rgb = channel255(geo["flagColor"])
    if geo["yes"]
      assert_operator rgb[1], :>, rgb[0]
      assert_operator rgb[1], :>, 120
    else
      assert_operator rgb[0], :>, rgb[1]
    end
    assert_operator geo["word"].to_f / geo["bar"].to_f, :>=, 0.45
    assert_operator geo["metaTop"], :<, geo["wordTop"] + geo["wordHeight"]
    assert_operator geo["height"], :<=, 120
    assert_operator geo["fillH"], :>=, 20
    theme = find("#street_quiz")["data-quiz-theme"]
    word = channel255(geo["wordColor"])
    surface = channel255(geo["bg"])
    if theme == "light"
      assert_operator word[0], :<, 90
      assert_operator surface[0], :>, 180
    else
      assert_operator word[0], :>, 180
      assert_operator surface[0], :<, 90
    end
  end

  def channel255(color)
    if (m = color.to_s.match(/rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)/))
      return m.captures.first(3).map { |n| n.to_f.round }
    end
    if (m = color.to_s.match(/color\(\s*srgb\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)/i))
      return m.captures.first(3).map { |n| (n.to_f * 255).round }
    end
    [ 0, 0, 0 ]
  end

  def assert_apex_above_sheet!
    metrics = page.evaluate_script(<<~JS)
      (function() {
        var apex = document.querySelector("#street_quiz .street-quiz-apex");
        var sheet = document.querySelector("#street_quiz .quiz-sheet") || document.querySelector("#street_quiz .play-sheet");
        var card = document.querySelector("#street_quiz .street-quiz-card");
        var overlay = document.querySelector("#street_quiz.is-overlay");
        if (!apex || !sheet) return null;
        var star = apex.getBoundingClientRect();
        var ivory = sheet.getBoundingClientRect();
        var x = Math.round(star.left + star.width / 2);
        var y = Math.round(star.top + star.height / 2);
        apex.style.pointerEvents = "auto";
        var stack = document.elementsFromPoint(x, y).map(function(el) {
          return el.className && String(el.className) || el.tagName;
        });
        apex.style.pointerEvents = "";
        return {
          overlay: !!overlay,
          overflow: overlay ? getComputedStyle(sheet).overflow : (card ? getComputedStyle(card).overflow : ""),
          protrude: ivory.top - star.top,
          starHeight: star.height,
          metal: getComputedStyle(apex, "::before").backgroundImage,
          stack: stack.slice(0, 6)
        };
      })()
    JS
    assert metrics, "quiz sheet should render an apex star"
    assert_equal "visible", metrics["overflow"], "quiz card overflow must not clip the apex star"
    assert_operator metrics["protrude"], :>=, 6, "apex star should sit on the quiz sheet hairline (#{metrics.inspect})"
    assert_operator metrics["starHeight"], :>=, 18, "apex star should be large enough to read (#{metrics.inspect})"
    assert_match(/linear-gradient/, metrics["metal"].to_s, "apex star should be gold-leaf metal, not a flat icon (#{metrics.inspect})")
    joined = Array(metrics["stack"]).join(" ")
    overlay_glass = metrics["overlay"] && !joined.match?(/street-quiz-apex|picto/)
    unless overlay_glass
      assert_match(/street-quiz-apex|picto/, joined, "apex star should paint above the still (#{metrics.inspect})")
      still_at = Array(metrics["stack"]).index { |name| name.to_s.include?("challenge-story") }
      apex_at = Array(metrics["stack"]).index { |name| name.to_s.include?("street-quiz-apex") || name.to_s.include?("picto") }
      if still_at && apex_at
        assert_operator apex_at, :<, still_at, "apex star must stack above the painting (#{metrics.inspect})"
      end
    end
  end

  def sheet_top
    page.evaluate_script(<<~JS)
      (function() {
        var sheet = document.querySelector("#street_quiz .quiz-sheet") || document.querySelector("#street_quiz .play-sheet");
        if (!sheet) return 0;
        return sheet.getBoundingClientRect().top / window.innerHeight;
      })()
    JS
  end

  def score_top
    page.evaluate_script(<<~JS)
      (function() {
        var score = document.querySelector("#street_quiz .street-score");
        if (!score) return 1;
        return score.getBoundingClientRect().top / window.innerHeight;
      })()
    JS
  end

  def swipe(selector, dx:, dy:)
    page.execute_script(<<~JS, selector, dx, dy)
      var el = document.querySelector(arguments[0]);
      var r = el.getBoundingClientRect();
      var x = r.left + r.width * 0.5;
      var y = r.top + r.height * 0.4;
      var dx = arguments[1];
      var dy = arguments[2];
      var fire = function(type, cx, cy) {
        el.dispatchEvent(new PointerEvent(type, {
          bubbles: true, cancelable: true, pointerId: 1, pointerType: "touch",
          clientX: cx, clientY: cy
        }));
      };
      fire("pointerdown", x, y);
      fire("pointermove", x + dx * 0.35, y + dy * 0.35);
      fire("pointermove", x + dx, y + dy);
      fire("pointerup", x + dx, y + dy);
    JS
  end

  def wait_for_brush_fonts!
    page.evaluate_async_script(<<~JS)
      var done = arguments[0];
      if (!document.fonts || !document.fonts.load) { done(); return; }
      document.fonts.load("700 48px Kalam").then(function() { done(); }).catch(function() { done(); });
    JS
  end

  def wait_for_image!(selector)
    page.evaluate_async_script(<<~JS, selector)
      const selector = arguments[0]
      const done = arguments[1]
      const image = document.querySelector(selector)
      if (!image) { done(false); return }
      if (image.complete && image.naturalWidth > 0) { done(true); return }
      const finish = () => done(image.naturalWidth > 0)
      image.addEventListener("load", finish, { once: true })
      image.addEventListener("error", finish, { once: true })
    JS
  end

  def assert_outgoing_section_uses_available_width
    geometry = page.evaluate_script(<<~JS)
      (function() {
        const reference = document.querySelector('.duel-campus-section.is-results').getBoundingClientRect()
        const section = document.querySelector('.duel-campus-section.is-outgoing').getBoundingClientRect()
        return { referenceWidth: reference.width, sectionWidth: section.width }
      })()
    JS
    assert_in_delta geometry["referenceWidth"], geometry["sectionWidth"], 1
  end

  def assert_duel_priority_clears_summary!(width:)
    geometry = page.evaluate_script(<<~JS)
      (function() {
        const hero = document.querySelector('.duel-campus-hero').getBoundingClientRect()
        const summary = document.querySelector('.duel-campus-counts').getBoundingClientRect()
        const priority = document.querySelector('.duel-campus-priority').getBoundingClientRect()
        return {
          heroBottom: hero.bottom,
          summaryBottom: summary.bottom,
          priorityTop: priority.top,
          gap: priority.top - summary.bottom
        }
      })()
    JS
    assert_operator geometry["priorityTop"], :>=, geometry["heroBottom"] - 1,
      "next-pack card must not overlap the hero at #{width}px: #{geometry.inspect}"
    assert_operator geometry["gap"], :>=, 16,
      "next-pack card needs at least one spacing unit below the summary at #{width}px: #{geometry.inspect}"
  end

  def shot(name)
    FileUtils.mkdir_p(SHOT_DIR)
    FileUtils.mkdir_p(TEMPLE_SHOT_DIR)
    path = SHOT_DIR.join("#{name}.png")
    page.save_screenshot(path)
    temple_path = TEMPLE_SHOT_DIR.join("#{name}.png")
    FileUtils.cp(path, temple_path) if path.exist?
    warn "street-shot #{path}"
    warn "temple-shot #{temple_path}" if path.exist?
  end
end
