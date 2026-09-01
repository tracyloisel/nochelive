require "application_system_test_case"

class HubStreamingRailsVisualTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/street-shots/editorial-convergence")
  VIEWPORTS = [
    [ 320, 568 ],
    [ 390, 844 ],
    [ 768, 1024 ],
    [ 1024, 768 ],
    [ 1440, 900 ],
    [ 1536, 1024 ],
    [ 1920, 1080 ]
  ].freeze
  DESKTOP_WIDTH = 1200

  setup do
    @person = people(:pili)
    @ward = @person.ward
    @ward.update!(scripture_circle_mode: "active", time_zone: "Europe/Madrid")
    @week = create_current_expedition_program!
    @question = seed_quiz_reading!
    seed_recent_gain!
    seed_circle_activity!
    seed_published_event!
    ChurchVideos::Catalog.forced_result = video_highlights_catalog
    thumbnail = Rails.root.join("media/masters/media/church/videos/celestial-video-sanctuary-v1.webp").binread
    ChurchVideos::Thumbnail.forced_response = ChurchVideos::Thumbnail::Image.new(body: thumbnail, content_type: "image/webp")
    sign_in_fixture_person_direct!(@person)
    page.driver.browser.manage.add_cookie(name: Locale::COOKIE.to_s, value: "fr", path: "/")
  end

  teardown do
    ChurchVideos::Catalog.forced_result = nil
    ChurchVideos::Thumbnail.forced_response = nil
  end

  test "an active player sees one Hero then Today expedition Rama and artwork rails in both themes" do
    theme_worlds.each do |theme, world|
      Hubs::Backdrop.entries = [ world ]

      VIEWPORTS.each do |width, height|
        set_system_viewport(width, height)
        visit root_path

        assert_selector "html[lang='fr']"
        assert_selector "#street_world[data-hub-theme='#{theme}']"
        assert_member_editorial_contract!
        assert_editorial_geometry!(width:, height:)
        assert_hero_gameops_readability!(width:) if [ 390, 768, 1440 ].include?(width)
        assert_today_readability!(width:) if [ 390, 1440 ].include?(width)
        assert_mobile_hero_controls! if width == 390
        assert_rail_geometry!(width:)
        assert_rama_tile_readability! if [ 390, 1440 ].include?(width) && page.has_css?(".hub-rama-carousel")
        assert_watch_rail_geometry!(width:) if [ 390, 1440 ].include?(width)
        assert_navigation_affordance!(width:, height:)
        assert_first_viewport_invitation!(height:) if [ [ 390, 844 ], [ 1440, 900 ] ].include?([ width, height ])
        assert_long_hero_copy_does_not_collide!(theme:, width:, height:) if [ 390, 1440 ].include?(width)

        if [ 390, 768, 1440 ].include?(width)
          page.execute_script("document.querySelector('.street-hub-feed').scrollTop = 0")
          shot("hub-member-editorial-#{theme}-#{width}x#{height}-top")
        end

        assert_hud_transformation!(theme:, width:, height:) if [ 390, 768, 1440 ].include?(width)
        if [ 390, 1440 ].include?(width)
          shot_block(".hub-today", "hub-member-editorial-#{theme}-#{width}x#{height}-today")
          shot_block(".hub-expedition", "hub-member-editorial-#{theme}-#{width}x#{height}-expedition")
          shot_block(".hub-rama-carousel", "hub-member-editorial-#{theme}-#{width}x#{height}-rama")
          shot_block(".hub-explore-rail", "hub-member-editorial-#{theme}-#{width}x#{height}-explore")
        end

        logs = severe_browser_logs
        assert_empty logs, "Hub console errors at #{theme} #{width}x#{height}: #{logs.inspect}"
      end
    end
  ensure
    Hubs::Backdrop.reset!
  end

  test "a scheduled Rama Live keeps its chip title and artwork labels readable" do
    game_sessions(:david).update_columns(status: "finished", closed_at: Time.current)
    game_sessions(:elias).update_columns(status: "lobby", starts_at: 5.days.from_now, closed_at: nil)

    theme_worlds.each do |_theme, world|
      Hubs::Backdrop.entries = [ world ]

      [ [ 390, 844 ], [ 1440, 900 ] ].each do |width, height|
        set_system_viewport(width, height)
        visit root_path

        assert_selector ".hub-rama-carousel .hub-rama-presence__track > .hub-rama-card--live:first-child"
        assert_rama_tile_readability!
        logs = severe_browser_logs
        assert_empty logs, "Rama rail console errors at #{width}x#{height}: #{logs.inspect}"
      end
    end
  ensure
    Hubs::Backdrop.reset!
  end

  test "focus hover reduced motion and forced colors keep the editorial rails readable" do
    Hubs::Backdrop.entries = [ theme_worlds.fetch("dark") ]
    set_system_viewport(1440, 900)
    visit root_path

    card = find(".hub-rama-carousel .hub-rama-card", match: :first)
    page.execute_script("arguments[0].scrollIntoView({ block: 'center', inline: 'nearest' })", card.native)
    sleep 0.22
    hover_before = card_geometry(card)
    card.hover
    sleep 0.22
    hover_after = card_geometry(card)
    assert_in_delta hover_before.fetch("top"), hover_after.fetch("top"), 4, { before: hover_before, after: hover_after }.inspect

    assert_selector ".hub-content-card--reading.is-in_progress .hub-content-card__copy small",
      text: /42\s*%/
    assert_selector ".hub-content-card--reading.is-in_progress .hub-content-card__progress i[style*='42%']"
    reading = find(".hub-content-card--reading.is-in_progress")
    page.execute_script("arguments[0].focus()", reading.native)
    focus = page.evaluate_script(<<~JS)
      (function() {
        var card = document.querySelector('.hub-content-card--reading.is-in_progress');
        return { active: document.activeElement === card, outline: getComputedStyle(card).outlineStyle };
      })()
    JS
    assert focus.fetch("active"), focus.inspect
    refute_equal "none", focus.fetch("outline"), focus.inspect

    page.driver.browser.execute_cdp(
      "Emulation.setEmulatedMedia",
      features: [ { name: "prefers-reduced-motion", value: "reduce" } ]
    )
    visit root_path
    motion = page.evaluate_script(<<~JS)
      (function() {
        var story = getComputedStyle(document.querySelector('.hub-today__story'));
        var card = getComputedStyle(document.querySelector('.hub-content-card'));
        var art = getComputedStyle(document.querySelector('.hub-content-card__art img'));
        return {
          storyTransition: story.transitionDuration,
          cardTransition: card.transitionDuration,
          cardAnimation: card.animationName,
          artTransform: art.transform
        };
      })()
    JS
    assert motion.fetch("storyTransition").split(",").all? { |value| value.strip == "0s" }, motion.inspect
    assert motion.fetch("cardTransition").split(",").all? { |value| value.strip == "0s" }, motion.inspect
    assert_equal "none", motion.fetch("cardAnimation"), motion.inspect
    assert_equal "none", motion.fetch("artTransform"), motion.inspect

    page.driver.browser.execute_cdp(
      "Emulation.setEmulatedMedia",
      features: [ { name: "forced-colors", value: "active" } ]
    )
    set_system_viewport(390, 844)
    visit root_path
    forced = page.evaluate_script(<<~JS)
      (function() {
        var card = getComputedStyle(document.querySelector('.hub-content-card'));
        var today = getComputedStyle(document.querySelector('.hub-today__story'));
        var hud = getComputedStyle(document.querySelector('.home-menu.is-hud .quiz-hud'));
        return {
          overflow: document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
          cardContrast: card.backgroundColor !== card.color,
          cardBorder: card.borderTopColor,
          todayContrast: today.backgroundColor !== today.color,
          todayBorder: today.borderTopColor,
          hudContrast: hud.backgroundColor !== hud.color,
          hudBlurRemoved: hud.backdropFilter === 'none'
        };
      })()
    JS
    assert_not forced.fetch("overflow"), forced.inspect
    assert forced.fetch("cardContrast"), forced.inspect
    refute_equal "rgba(0, 0, 0, 0)", forced.fetch("cardBorder"), forced.inspect
    assert forced.fetch("todayContrast"), forced.inspect
    refute_equal "rgba(0, 0, 0, 0)", forced.fetch("todayBorder"), forced.inspect
    assert forced.fetch("hudContrast"), forced.inspect
    assert forced.fetch("hudBlurRemoved"), forced.inspect
    shot("hub-member-editorial-dark-390x844-forced-colors")
    logs = severe_browser_logs
    assert_empty logs, logs.inspect
  ensure
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: []) rescue nil
    Hubs::Backdrop.reset!
  end

  test "the one Hero CTA fits start and resume copy in every supported locale" do
    Hubs::Backdrop.entries = [ theme_worlds.fetch("dark") ]

    %w[es fr en pt-BR].each do |locale|
      page.driver.browser.manage.delete_all_cookies
      page.driver.browser.manage.add_cookie(name: Locale::COOKIE.to_s, value: locale, path: "/")

      [ [ 390, 844 ], [ 1440, 900 ] ].each do |width, height|
        set_system_viewport(width, height)
        visit root_path

        [
          I18n.t("hub.start_action", locale:),
          I18n.t("hub.resume_action", locale:, n: 10)
        ].each do |label|
          page.execute_script("document.querySelector('.hub-play__label').textContent = arguments[0]", label)
          geometry = page.evaluate_script(<<~JS)
            (function() {
              var button = document.querySelector('.hub-play').getBoundingClientRect();
              var label = document.querySelector('.hub-play__label').getBoundingClientRect();
              var arrow = document.querySelector('.hub-play__arrow').getBoundingClientRect();
              return {
                buttonLeft: button.left,
                buttonRight: button.right,
                labelLeft: label.left,
                labelRight: label.right,
                arrowLeft: arrow.left
              };
            })()
          JS

          assert_operator geometry.fetch("labelLeft"), :>=, geometry.fetch("buttonLeft") + 1, { locale:, width:, label:, geometry: }.inspect
          assert_operator geometry.fetch("labelRight"), :<=, geometry.fetch("buttonRight") - 1, { locale:, width:, label:, geometry: }.inspect
          assert_operator geometry.fetch("labelRight"), :<=, geometry.fetch("arrowLeft") - 6, { locale:, width:, label:, geometry: }.inspect
        end
      end
    end
  ensure
    Hubs::Backdrop.reset!
  end

  private

    def theme_worlds
      @theme_worlds ||= begin
        catalog = Array(YAML.safe_load_file(Hubs::Backdrop::CATALOG)["backdrops"])
        {
          "light" => catalog.find { |row| row["id"] == "salt-lake-temple-dawn" },
          "dark" => catalog.find { |row| row["id"] == "coronas-ungido" }
        }.tap { |worlds| assert worlds.values.all? }
      end
    end

    def create_current_expedition_program!
      program = StudyProgram.create!(
        slug: "hub-editorial-#{SecureRandom.hex(6)}",
        title: "Viens et suis-moi #{Date.current.year}",
        year: Date.current.year + 10,
        canon: "old_testament",
        locale: "fr",
        status: "published",
        source_url: "https://example.test/hub-editorial"
      )
      week = program.study_units.create!(
        slug: "week-current",
        kind: "week",
        position: 1,
        title: "Cette semaine : Psaumes",
        source_url: "https://example.test/hub-editorial/current",
        starts_on: Date.current.beginning_of_week,
        ends_on: Date.current.end_of_week,
        scripture_refs: [ "Psaumes" ],
        status: "published"
      )
      pack_ids = %w[
        exp_psalms_disappearing_voice exp_psalms_nameless_king
        exp_psalms_cry_stone_seek exp_psalms_house_table_city
        exp_psalms_suspended_harps exp_psalms_everything_breathes
      ]
      content = {
        "light" => { "fr" => "Le Dieu qui me relève est digne de louange." },
        "artwork" => "/media/expeditions/psalms-2026/home-key-art-v1.png",
        "questions" => [],
        "readings" => [
          {
            "study" => "ot/ps/102",
            "cite" => "Psaume 102",
            "labels" => { "fr" => "La prière qui traverse les générations" },
            "artwork" => "/media/study/psalms-refuge-2026.png"
          }
        ],
        "expedition" => {
          "id" => "weekly-psalms",
          "title" => { "fr" => "Ça aussi, c’est dans les Psaumes" },
          "subtitle" => { "fr" => "Six portes cachées" },
          "promise" => { "fr" => "Entre dans six histoires humaines." },
          "artwork" => "/media/expeditions/psalms-2026/home-key-art-v1.png",
          "pack_ids" => pack_ids,
          "packs" => pack_ids.map.with_index do |id, index|
            {
              "id" => id,
              "title" => { "fr" => "Porte #{index + 1}" },
              "hook" => { "fr" => "Une histoire à ouvrir." }
            }
          end
        }
      }
      week.study_quiz_versions.create!(
        version: 1,
        status: "published",
        editorial_locale: "fr",
        content:,
        content_digest: Digest::SHA256.hexdigest(content.to_json),
        published_at: Time.current
      )
      week
    end

    def seed_quiz_reading!
      question = QuizDefinition.catalog.find_pack("coronas").questions.find { |item| item.scripture&.study.present? }
      run = QuizRun.create!(
        person: @person,
        device_digest: "hub-editorial-reading",
        pack_id: question.pack_id,
        position: QuizDefinition::QUESTIONS_PER_PACK,
        score: 0,
        status: "finished",
        opened_at: Time.current
      )
      QuizAnswer.create!(
        quiz_run: run,
        device_digest: run.device_digest,
        pack_id: run.pack_id,
        question_id: question.id,
        choice_key: question.correct_choice,
        correct: false
      )
      ScriptureReadingProgress.create!(
        person: @person,
        locale: "fr",
        reference: question.scripture.study,
        first_opened_at: 2.days.ago,
        last_opened_at: Time.current,
        last_verse: 3,
        last_offset: 0,
        progress_ratio: 0.42
      )
      question
    end

    def seed_published_event!
      starts_at = 2.days.from_now.change(hour: 18, min: 0)
      event = WardEvent.create_draft!(
        ward: @ward,
        actor: "QA Hub",
        attributes: {
          kind: "music_activity",
          title: "Atelier musical",
          summary: "Un moment local réellement publié pour la vérification visuelle.",
          starts_at:,
          ends_at: starts_at + 2.hours,
          location_label: "Salle paroissiale",
          destination_path: ward_profile_path(@ward.code),
          artwork_path: "/media/church/worship.jpg"
        }
      )
      event.publish!(actor: "Présidence de Rama")
    end

    def seed_recent_gain!
      person = people(:carmen_garcia)
      question = QuizDefinition.catalog.find_pack("coronas").questions.second
      run = QuizRun.create!(
        person:,
        device_digest: "hub-editorial-gain",
        pack_id: question.pack_id,
        position: 1,
        score: 18,
        status: "finished",
        opened_at: 35.minutes.ago
      )
      run.quiz_answers.create!(
        device_digest: run.device_digest,
        pack_id: run.pack_id,
        question_id: question.id,
        choice_key: question.correct_choice,
        correct: true,
        points_awarded: 18
      )
    end

    def seed_circle_activity!
      thread = @ward.scripture_circle_threads.find_or_create_by!(reference: "ot/ps/52")
      root = thread.scripture_circle_posts.create!(
        ward: @ward,
        person: people(:carmen_garcia),
        kind: "question",
        locale: "fr",
        body: "Qu’est-ce qui demeure vraiment ?"
      )
      thread.scripture_circle_posts.create!(
        ward: @ward,
        person: @person,
        kind: "reply",
        parent: root,
        locale: "fr",
        body: "Dans la confiance, nos pas s’ancrent."
      )
    end

    def video_highlights_catalog
      videos = 6.times.map do |index|
        ChurchVideos::Catalog::Video.new(
          id: format("video%06d", index),
          title: "Une histoire officielle #{index + 1}",
          description: "",
          published_at: Time.utc(2026, 8, 20 - index, 12, 30),
          duration_seconds: 183 + index,
          made_for_kids: false
        )
      end
      ChurchVideos::Catalog::Result.new(videos:, error: nil)
    end

    def sign_in_fixture_person_direct!(person)
      session = ActionDispatch::Integration::Session.new(Rails.application)
      session.post enter_ward_path, params: { code: person.ward.code }
      session.post street_profile_path, params: { person_id: person.id, favorite_year: person.favorite_year }

      page.driver.browser.manage.delete_all_cookies
      visit root_path
      session.cookies.to_hash.each do |name, value|
        page.driver.browser.manage.add_cookie(name:, value:, path: "/")
      end
      visit root_path
    end

    def assert_member_editorial_contract!
      snapshot = page.evaluate_script(<<~JS)
        (function() {
          var feed = document.querySelector('.street-hub-feed');
          var order = Array.from(feed.children).map(function(node) {
            if (node.classList.contains('hub-hero')) return 'hero';
            if (node.classList.contains('hub-today')) return 'today';
            if (node.classList.contains('hub-expedition')) return 'expedition';
            if (node.classList.contains('hub-rama-carousel')) return 'rama';
            if (node.classList.contains('hub-explore-rail')) return 'explore';
            if (node.id === 'hub_watch_rail') return 'watch';
            if (node.classList.contains('hub-install--compact')) return 'install';
            return null;
          }).filter(Boolean);
          var heroImage = feed.querySelector('.hub-hero .hub-slide-still');
          var frame = feed.querySelector('turbo-frame#hub_watch_rail');
          return {
            order: order,
            heroCount: feed.querySelectorAll(':scope > .hub-hero').length,
            heroSlides: feed.querySelectorAll('.hub-hero .hub-slide').length,
            heroActions: feed.querySelectorAll('.hub-hero .hub-play').length,
            heroProgress: feed.querySelectorAll('.hub-hero .hub-hero-progress').length,
            heroLoading: heroImage && heroImage.getAttribute('loading'),
            heroPriority: heroImage && heroImage.getAttribute('fetchpriority'),
            todayKind: feed.querySelector('.hub-today')?.dataset.todayKind,
            todayStories: feed.querySelectorAll('.hub-today__story').length,
            expedition: feed.querySelectorAll(':scope > .hub-expedition').length,
            expeditionChips: feed.querySelectorAll('.hub-expedition ol, .hub-expedition li').length,
            ramaCards: feed.querySelectorAll('.hub-rama-presence__track > [role="listitem"]').length,
            circle: feed.querySelectorAll('.hub-rama-event--circle').length,
            challenge: feed.querySelectorAll('.hub-rama-event--challenge').length,
            exploreCards: feed.querySelectorAll('.hub-explore-rail .hub-content-card').length,
            watchLoading: frame && frame.getAttribute('loading'),
            watchSrc: frame && frame.getAttribute('src'),
            now: feed.querySelectorAll(':scope > .hub-now').length,
            identity: feed.querySelectorAll(':scope > .hub-identity-empty').length,
            legacyDashboard: feed.querySelectorAll('.hub-hero-league, .hub-hero-gains, .hub-reward, .hub-rama-card--challenge, .hub-rama-card--videos').length,
            eagerBelowHero: feed.querySelectorAll(':scope > :not(.hub-hero) img[loading="eager"], :scope > :not(.hub-hero) img[fetchpriority="high"]').length,
            packInHud: document.querySelectorAll('.quiz-hud-pack').length
          };
        })()
      JS

      assert_equal %w[hero today expedition rama explore watch install], snapshot.fetch("order"), snapshot.inspect
      assert_equal 1, snapshot.fetch("heroCount"), snapshot.inspect
      assert_equal 1, snapshot.fetch("heroSlides"), snapshot.inspect
      assert_equal 1, snapshot.fetch("heroActions"), snapshot.inspect
      assert_equal 1, snapshot.fetch("heroProgress"), snapshot.inspect
      assert_equal "eager", snapshot.fetch("heroLoading"), snapshot.inspect
      assert_equal "high", snapshot.fetch("heroPriority"), snapshot.inspect
      assert_equal "live", snapshot.fetch("todayKind"), snapshot.inspect
      assert_equal 1, snapshot.fetch("todayStories"), snapshot.inspect
      assert_equal 1, snapshot.fetch("expedition"), snapshot.inspect
      assert_equal 0, snapshot.fetch("expeditionChips"), snapshot.inspect
      assert_includes 1..3, snapshot.fetch("ramaCards"), snapshot.inspect
      assert_equal 1, snapshot.fetch("circle"), snapshot.inspect
      assert_includes 0..1, snapshot.fetch("challenge"), snapshot.inspect
      assert_operator snapshot.fetch("exploreCards"), :>=, 2, snapshot.inspect
      assert_equal "lazy", snapshot.fetch("watchLoading"), snapshot.inspect
      assert_equal hub_video_highlights_path(locale: :fr), snapshot.fetch("watchSrc"), snapshot.inspect
      assert_equal 0, snapshot.fetch("now"), snapshot.inspect
      assert_equal 0, snapshot.fetch("identity"), snapshot.inspect
      assert_equal 0, snapshot.fetch("legacyDashboard"), snapshot.inspect
      assert_equal 0, snapshot.fetch("eagerBelowHero"), snapshot.inspect
      assert_equal 0, snapshot.fetch("packInHud"), snapshot.inspect
      assert_no_text(/\b0\s+(couronnes?|défis?|invitations?|soirées?)\b/i)
      assert_selector ".hub-explore-rail .hub-content-card[href='#{scripture_path(@question.scripture.study, cite: @question.scripture.cite)}']", count: 1
    end

    def assert_editorial_geometry!(width:, height:)
      geometry = page.evaluate_script(<<~JS)
        (function() {
          var visible = function(node) {
            if (!node) return false;
            var style = getComputedStyle(node);
            var box = node.getBoundingClientRect();
            return !node.hidden && style.display !== 'none' && style.visibility !== 'hidden' && box.width > 0 && box.height > 0;
          };
          var rect = function(node) {
            var box = node.getBoundingClientRect();
            return { left: box.left, right: box.right, top: box.top, bottom: box.bottom, width: box.width, height: box.height };
          };
          var targets = Array.from(document.querySelectorAll(
            '.hub-hero .hub-play, .hub-today__story, .hub-expedition__cta, .hub-rama-carousel a, .hub-rama-carousel button, .hub-explore-rail .hub-content-card, .hub-install--compact a, .hub-install--compact button'
          )).filter(visible).map(rect);
          var hero = document.querySelector('.hub-hero-stage');
          var play = document.querySelector('.hub-hero .hub-play');
          var playBox = play.getBoundingClientRect();
          var playLabel = play.querySelector('.hub-play__label');
          var playLabelBox = playLabel && playLabel.getBoundingClientRect();
          var playContentClipped = !playLabel ||
            playLabel.scrollWidth > playLabel.clientWidth + 1 ||
            playLabelBox.left < playBox.left - 1 || playLabelBox.right > playBox.right + 1;
          var playMetrics = {
            clientWidth: play.clientWidth,
            scrollWidth: play.scrollWidth,
            labelClientWidth: playLabel && playLabel.clientWidth,
            labelScrollWidth: playLabel && playLabel.scrollWidth,
            children: Array.from(play.children).map(function(child) {
              var box = child.getBoundingClientRect();
              return { className: child.className, left: box.left, right: box.right, width: box.width, height: box.height };
            })
          };
          var today = document.querySelector('.hub-today');
          var expedition = document.querySelector('.hub-expedition');
          var rama = document.querySelector('.hub-rama-carousel');
          return {
            overflow: document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
            targets: targets,
            heroActionClipped: playContentClipped,
            heroActionMetrics: playMetrics,
            hero: rect(hero),
            today: rect(today),
            expedition: rect(expedition),
            rama: rect(rama),
            hudOutsideFeed: !document.querySelector('.street-hub-feed').contains(document.querySelector('body > .home-menu.is-hud'))
          };
        })()
      JS

      assert_not geometry.fetch("overflow"), { width:, height:, geometry: }.inspect
      assert geometry.fetch("targets").all? { |target| target.fetch("width") >= 44 && target.fetch("height") >= 44 }, geometry.inspect
      assert_not geometry.fetch("heroActionClipped"), geometry.inspect
      assert geometry.fetch("hudOutsideFeed"), geometry.inspect
      assert_in_delta 0, geometry.dig("hero", "top"), 1, geometry.inspect
      assert_operator geometry.dig("today", "top"), :>=, geometry.dig("hero", "bottom") - 1, geometry.inspect
      assert_operator geometry.dig("expedition", "top"), :>, geometry.dig("today", "bottom"), geometry.inspect
      assert_operator geometry.dig("rama", "top"), :>=, geometry.dig("expedition", "bottom") + 20, geometry.inspect
      if [ [ 390, 844 ], [ 1440, 900 ] ].include?([ width, height ])
        assert_in_delta 0, geometry.dig("hero", "left"), 1, geometry.inspect
        assert_in_delta width, geometry.dig("hero", "right"), 1, geometry.inspect
        assert_in_delta width, geometry.dig("hero", "width"), 2, geometry.inspect
      end
      assert_equal 1, page.all(".hub-hero .hub-play").size
      assert_no_selector ".hub-voyage-nav, .hub-dot"
    end

    def assert_rail_geometry!(width:)
      rails = page.evaluate_script(<<~JS)
        Array.from(document.querySelectorAll('.hub-rama-carousel .hub-content-rail__track, .hub-explore-rail .hub-content-rail__track')).map(function(track) {
          var cards = Array.from(track.querySelectorAll(':scope > [role="listitem"]')).map(function(card) {
            var rect = card.getBoundingClientRect();
            return { left: rect.left, right: rect.right, top: rect.top, width: rect.width, height: rect.height };
          });
          var style = getComputedStyle(track);
          return {
            overflowX: style.overflowX,
            snap: style.scrollSnapType,
            clientWidth: track.clientWidth,
            scrollWidth: track.scrollWidth,
            cards: cards
          };
        })
      JS

      assert_equal 2, rails.length, rails.inspect
      rails.each do |rail|
        assert_includes %w[auto scroll], rail.fetch("overflowX"), rail.inspect
        assert_includes rail.fetch("snap"), "x", rail.inspect
        assert_operator rail.fetch("cards").length, :>=, 2, rail.inspect
        tops = rail.fetch("cards").map { |card| card.fetch("top") }
        assert tops.all? { |top| (top - tops.first).abs <= 2 }, rail.inspect
        assert rail.fetch("cards").all? { |card| card.fetch("width") >= 180 && card.fetch("height") >= 180 }, rail.inspect

        next unless width <= 390

        first, second = rail.fetch("cards").first(2)
        assert_operator rail.fetch("scrollWidth"), :>, rail.fetch("clientWidth") + 24, rail.inspect
        assert_operator first.fetch("left"), :>=, 12, rail.inspect
        assert_operator first.fetch("left"), :<=, 24, rail.inspect
        assert_operator second.fetch("left"), :>, first.fetch("right"), rail.inspect
        assert_operator second.fetch("left"), :<, width - 16, rail.inspect
        assert_operator second.fetch("right"), :>, width + 24, rail.inspect
      end
    end

    def assert_today_readability!(width:)
      geometry = page.evaluate_script(<<~JS)
        (function() {
          var today = document.querySelector('.hub-today');
          var story = today.querySelector('.hub-today__story');
          var copy = today.querySelector('.hub-today__copy');
          var dailyText = Array.from(copy.querySelectorAll('.hub-today__setup, .hub-today__body, em'))
            .filter(function(node) { return getComputedStyle(node).display !== 'none'; })
            .map(function(node) { return parseFloat(getComputedStyle(node).fontSize); });
          return {
            kind: today.dataset.todayKind,
            storyHeight: story.getBoundingClientRect().height,
            copyHeight: copy.getBoundingClientRect().height,
            copyClientHeight: copy.clientHeight,
            copyScrollHeight: copy.scrollHeight,
            dailyTextMinimum: dailyText.length ? Math.min.apply(Math, dailyText) : null
          };
        })()
      JS

      assert_operator geometry.fetch("storyHeight"), :>=, 360, { width:, geometry: }.inspect
      assert_operator geometry.fetch("copyHeight"), :>=, 360, { width:, geometry: }.inspect
      assert_operator geometry.fetch("copyScrollHeight"), :<=, geometry.fetch("copyClientHeight") + 1, { width:, geometry: }.inspect
      if geometry.fetch("kind") == "daily_discovery"
        assert_operator geometry.fetch("dailyTextMinimum"), :>=, 17, { width:, geometry: }.inspect
      end
    end

    def assert_mobile_hero_controls!
      geometry = page.evaluate_script(<<~JS)
        (function() {
          var play = document.querySelector('.hub-hero .hub-play');
          var playBox = play.getBoundingClientRect();
          var playStyle = getComputedStyle(play);
          var emblem = document.querySelector('.hub-hero-progress__emblem');
          var emblemBox = emblem.getBoundingClientRect();
          var emblemStyle = getComputedStyle(emblem);
          var iconBox = emblem.querySelector('svg').getBoundingClientRect();
          var rail = document.querySelector('.hub-hero-progress__rail');
          var railBox = rail.getBoundingClientRect();
          var railStyle = getComputedStyle(rail);
          return {
            playHeight: playBox.height,
            playRadius: parseFloat(playStyle.borderTopLeftRadius),
            emblemWidth: emblemBox.width,
            emblemHeight: emblemBox.height,
            emblemBorder: parseFloat(emblemStyle.borderTopWidth),
            emblemRadius: parseFloat(emblemStyle.borderTopLeftRadius),
            emblemIconDeltaX: Math.abs((emblemBox.left + emblemBox.width / 2) - (iconBox.left + iconBox.width / 2)),
            emblemIconDeltaY: Math.abs((emblemBox.top + emblemBox.height / 2) - (iconBox.top + iconBox.height / 2)),
            railDisplay: railStyle.display,
            railWidth: railBox.width,
            railHeight: railBox.height
          };
        })()
      JS

      assert_includes 10.0..16.0, geometry.fetch("playRadius"), geometry.inspect
      assert_operator geometry.fetch("playRadius"), :<, geometry.fetch("playHeight") / 3.0, geometry.inspect
      assert_operator geometry.fetch("emblemWidth"), :>=, 44, geometry.inspect
      assert_in_delta geometry.fetch("emblemWidth"), geometry.fetch("emblemHeight"), 1, geometry.inspect
      assert_operator geometry.fetch("emblemBorder"), :>=, 2, geometry.inspect
      assert_operator geometry.fetch("emblemRadius"), :>=, geometry.fetch("emblemWidth") / 2.0 - 1, geometry.inspect
      assert_operator geometry.fetch("emblemIconDeltaX"), :<=, 1, geometry.inspect
      assert_operator geometry.fetch("emblemIconDeltaY"), :<=, 1, geometry.inspect
      assert_equal "block", geometry.fetch("railDisplay"), geometry.inspect
      assert_operator geometry.fetch("railWidth"), :>, 80, geometry.inspect
      assert_operator geometry.fetch("railHeight"), :>=, 6, geometry.inspect
    end

    def assert_hero_gameops_readability!(width:)
      geometry = page.evaluate_script(<<~JS)
        (function() {
          var stage = document.querySelector('.hub-hero-stage').getBoundingClientRect();
          var group = document.querySelector('.hub-hero-gameops').getBoundingClientRect();
          var chipMetrics = Array.from(document.querySelectorAll('.hub-hero-gameops > p')).map(function(chip) {
            var box = chip.getBoundingClientRect();
            var style = getComputedStyle(chip);
            var colorParts = style.backgroundColor.match(/[\\d.]+/g);
            return {
              left: box.left,
              right: box.right,
              width: box.width,
              height: box.height,
              fontSize: parseFloat(style.fontSize),
              borderWidth: parseFloat(style.borderTopWidth),
              background: style.background,
              backgroundAlpha: colorParts && colorParts.length === 4 ? parseFloat(colorParts[3]) : 1,
              backdropFilter: style.backdropFilter,
              overflow: chip.scrollWidth > chip.clientWidth + 1
            };
          });
          var titleStyle = getComputedStyle(document.querySelector('.hub-hero-title'));
          var ledeStyle = getComputedStyle(document.querySelector('.hub-hero-lede'));
          var copyStyle = getComputedStyle(document.querySelector('.hub-slide-copy-top'));
          return {
            stage: { left: stage.left, right: stage.right },
            group: { left: group.left, right: group.right },
            chips: chipMetrics,
            copyBackground: copyStyle.backgroundColor,
            copyBorder: parseFloat(copyStyle.borderTopWidth),
            titleShadow: titleStyle.textShadow,
            titleStroke: parseFloat(titleStyle.getPropertyValue('-webkit-text-stroke-width')),
            ledeShadow: ledeStyle.textShadow
          };
        })()
      JS

      assert_equal 2, geometry.fetch("chips").length, { width:, geometry: }.inspect
      assert_operator geometry.dig("group", "left"), :>=, geometry.dig("stage", "left") - 1, geometry.inspect
      assert_operator geometry.dig("group", "right"), :<=, geometry.dig("stage", "right") + 1, geometry.inspect
      assert geometry.fetch("chips").all? { |chip| chip.fetch("fontSize") >= 14 }, geometry.inspect
      assert geometry.fetch("chips").all? { |chip| chip.fetch("height") >= 34 }, geometry.inspect
      assert_in_delta geometry.dig("chips", 0, "height"), geometry.dig("chips", 1, "height"), 1, geometry.inspect
      assert geometry.fetch("chips").all? { |chip| chip.fetch("borderWidth") >= 1 }, geometry.inspect
      assert geometry.fetch("chips").all? { |chip| chip.fetch("background") !~ /rgba\(0, 0, 0, 0\) none/ }, geometry.inspect
      assert geometry.fetch("chips").all? { |chip| chip.fetch("backgroundAlpha").between?(0.3, 0.55) }, geometry.inspect
      assert geometry.fetch("chips").all? { |chip| chip.fetch("backdropFilter") != "none" }, geometry.inspect
      assert geometry.fetch("chips").none? { |chip| chip.fetch("overflow") }, geometry.inspect
      assert_includes [ "rgba(0, 0, 0, 0)", "transparent" ], geometry.fetch("copyBackground"), geometry.inspect
      assert_equal 0, geometry.fetch("copyBorder"), geometry.inspect
      refute_equal "none", geometry.fetch("titleShadow"), geometry.inspect
      assert_operator geometry.fetch("titleStroke"), :>=, 0.4, geometry.inspect
      refute_equal "none", geometry.fetch("ledeShadow"), geometry.inspect
    end

    def assert_watch_rail_geometry!(width:)
      page.execute_script(<<~JS)
        document.querySelector('turbo-frame#hub_watch_rail').scrollIntoView({ block: 'center', behavior: 'auto' });
      JS
      assert_selector "turbo-frame#hub_watch_rail .hub-watch-rail"
      geometry = page.evaluate_script(<<~JS)
        (function() {
          var explore = document.querySelector('.hub-explore-rail').getBoundingClientRect();
          var frame = document.querySelector('turbo-frame#hub_watch_rail').getBoundingClientRect();
          var overlay = document.querySelector('.hub-watch-rail .hub-content-card__play');
          var overlayBox = overlay.getBoundingClientRect();
          var overlayStyle = getComputedStyle(overlay);
          var transparentPlate = [ 'transparent', 'rgba(0, 0, 0, 0)' ].includes(overlayStyle.backgroundColor);
          var icon = overlay.querySelector('.picto-play');
          var circle = icon && icon.querySelector('circle');
          var triangle = icon && icon.querySelector('path');
          var contrast = function(first, second) {
            var channels = function(value) {
              var match = String(value).match(/[\\d.]+/g);
              if (!match || match.length < 3) return null;
              return match.slice(0, 3).map(function(channel) {
                var normalized = Number(channel) / 255;
                return normalized <= 0.04045 ? normalized / 12.92 : Math.pow((normalized + 0.055) / 1.055, 2.4);
              });
            };
            var a = channels(first);
            var b = channels(second);
            if (!a || !b) return null;
            var luminance = function(rgb) { return 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]; };
            var light = Math.max(luminance(a), luminance(b));
            var dark = Math.min(luminance(a), luminance(b));
            return (light + 0.05) / (dark + 0.05);
          };
          var circleFill = circle && getComputedStyle(circle).fill;
          var triangleFill = triangle && getComputedStyle(triangle).fill;
          return {
            gap: frame.top - explore.bottom,
            exploreLeft: explore.left,
            exploreWidth: explore.width,
            frameLeft: frame.left,
            frameWidth: frame.width,
            overlayWidth: overlayBox.width,
            overlayHeight: overlayBox.height,
            overlayHasPlate: !transparentPlate || overlayStyle.backgroundImage !== 'none',
            iconPresent: !!icon,
            circleFill: circleFill,
            triangleFill: triangleFill,
            iconContrast: contrast(circleFill, triangleFill)
          };
        })()
      JS

      assert_operator geometry.fetch("gap"), :>=, 40, { width:, geometry: }.inspect
      assert_in_delta geometry.fetch("exploreLeft"), geometry.fetch("frameLeft"), 1, geometry.inspect
      assert_in_delta geometry.fetch("exploreWidth"), geometry.fetch("frameWidth"), 2, geometry.inspect
      assert_operator geometry.fetch("overlayWidth"), :>=, 44, geometry.inspect
      assert_operator geometry.fetch("overlayHeight"), :>=, 44, geometry.inspect
      assert geometry.fetch("overlayHasPlate"), geometry.inspect
      assert geometry.fetch("iconPresent"), geometry.inspect
      refute_equal geometry.fetch("circleFill"), geometry.fetch("triangleFill"), geometry.inspect
      assert_operator geometry.fetch("iconContrast"), :>=, 3.0, geometry.inspect
    end

    def assert_rama_tile_readability!
      geometry = page.evaluate_script(<<~JS)
        (function() {
          var carousel = document.querySelector('.hub-rama-carousel');
          var track = carousel.querySelector('.hub-rama-presence__track');
          var liveCard = track.querySelector('.hub-rama-card--live');
          var within = function(inner, outer) {
            var item = inner.getBoundingClientRect();
            var container = outer.getBoundingClientRect();
            return item.left >= container.left - 1 &&
              item.right <= container.right + 1 &&
              item.top >= container.top - 1 &&
              item.bottom <= container.bottom + 1;
          };
          var hasPlate = function(node) {
            var style = getComputedStyle(node);
            var transparent = [ 'transparent', 'rgba(0, 0, 0, 0)' ].includes(style.backgroundColor);
            return !transparent || style.backgroundImage !== 'none';
          };
          var hiddenBadges = Array.from(carousel.querySelectorAll('.hub-live-badge[hidden]'));
          var eventKickers = Array.from(carousel.querySelectorAll('.hub-rama-event__kicker'));
          var eventMetas = Array.from(carousel.querySelectorAll('.hub-rama-event__meta'));
          var eventTitles = Array.from(carousel.querySelectorAll('.hub-rama-event strong'));
          var live = null;
          if (liveCard) {
            var header = liveCard.querySelector('.hub-live-head');
            var kicker = liveCard.querySelector('.hub-live-head .hub-kicker');
            var title = liveCard.querySelector('.hub-live-special');
            live = {
              isFirstCard: track.firstElementChild === liveCard,
              headerPresent: !!header,
              kickerPresent: !!kicker,
              headerWithinCard: !!header && within(header, liveCard),
              kickerWithinCard: !!kicker && within(kicker, liveCard),
              titleClamp: title && getComputedStyle(title).webkitLineClamp
            };
          }
          return {
            live: live,
            hiddenBadgesAreHidden: hiddenBadges.every(function(badge) { return getComputedStyle(badge).display === 'none'; }),
            kickerCount: eventKickers.length,
            kickersHavePlate: eventKickers.every(hasPlate),
            metaCount: eventMetas.length,
            metasHavePlate: eventMetas.every(hasPlate),
            titleCount: eventTitles.length,
            titlesHaveShadow: eventTitles.every(function(title) { return getComputedStyle(title).textShadow !== 'none'; })
          };
        })()
      JS

      if geometry.fetch("live")
        assert geometry.dig("live", "isFirstCard"), geometry.inspect
        assert geometry.dig("live", "headerPresent"), geometry.inspect
        assert geometry.dig("live", "kickerPresent"), geometry.inspect
        assert geometry.dig("live", "headerWithinCard"), geometry.inspect
        assert geometry.dig("live", "kickerWithinCard"), geometry.inspect
        assert_equal "2", geometry.dig("live", "titleClamp"), geometry.inspect
      end
      assert geometry.fetch("hiddenBadgesAreHidden"), geometry.inspect
      assert geometry.fetch("kickersHavePlate"), geometry.inspect if geometry.fetch("kickerCount").positive?
      assert geometry.fetch("metasHavePlate"), geometry.inspect if geometry.fetch("metaCount").positive?
      assert geometry.fetch("titlesHaveShadow"), geometry.inspect if geometry.fetch("titleCount").positive?
    end

    def assert_first_viewport_invitation!(height:)
      first_view = page.evaluate_script(<<~JS)
        (function() {
          var rect = function(selector) {
            var box = document.querySelector(selector).getBoundingClientRect();
            return { top: box.top, bottom: box.bottom };
          };
          return {
            play: rect('.hub-hero .hub-play'),
            progress: rect('.hub-hero-progress'),
            todayTitle: rect('.hub-today__head'),
            todayStory: rect('.hub-today__story'),
            todayEyebrow: rect('.hub-today__eyebrow'),
            todayHeadline: rect('.hub-today__copy > strong')
          };
        })()
      JS
      assert_operator first_view.dig("play", "bottom"), :<=, height, first_view.inspect
      assert_operator first_view.dig("progress", "bottom"), :<=, height, first_view.inspect
      assert_operator first_view.dig("todayTitle", "top"), :<, height, first_view.inspect
      assert_operator first_view.dig("todayTitle", "bottom"), :<=, height, first_view.inspect
      assert_operator first_view.dig("todayStory", "top"), :<, height, first_view.inspect
      assert_operator first_view.dig("todayEyebrow", "bottom"), :<=, height, first_view.inspect
      assert_operator first_view.dig("todayHeadline", "top"), :<, height, first_view.inspect
    end

    def assert_hud_transformation!(theme:, width:, height:)
      page.execute_script(<<~JS)
        document.querySelector('.street-hub-feed').scrollTop = 0;
        document.querySelector('.street-hub-feed').dispatchEvent(new Event('scroll'));
      JS
      assert_no_selector ".home-menu.is-hud.is-compact", visible: :all
      sleep 0.32
      resting = hud_state_snapshot
      assert_operator resting.fetch("radius"), :<=, 1.0, resting.inspect
      assert_operator resting.fetch("left"), :<=, 1.0, resting.inspect
      assert_equal 0, resting.fetch("packCount"), resting.inspect

      page.execute_script(<<~JS)
        document.querySelector('.street-hub-feed').scrollTop = 128;
        document.querySelector('.street-hub-feed').dispatchEvent(new Event('scroll'));
      JS
      assert_selector ".home-menu.is-hud.is-compact", visible: :all
      sleep 0.34
      floating = hud_state_snapshot
      assert_operator floating.fetch("radius"), :>=, 20.0, floating.inspect
      assert_operator floating.fetch("left"), :>=, 11.0, floating.inspect
      assert_operator floating.fetch("height"), :<, resting.fetch("height"), { resting:, floating: }.inspect
      refute_equal resting.fetch("background"), floating.fetch("background"), { resting:, floating: }.inspect
      assert_equal 0, floating.fetch("packCount"), floating.inspect
      shot("hub-member-hud-#{theme}-#{width}x#{height}-floating")
    ensure
      page.execute_script(<<~JS) rescue nil
        var feed = document.querySelector('.street-hub-feed');
        if (feed) {
          feed.scrollTop = 0;
          feed.dispatchEvent(new Event('scroll'));
        }
      JS
    end

    def hud_state_snapshot
      page.evaluate_script(<<~JS)
        (function() {
          var menu = document.querySelector('.home-menu.is-hud');
          var hud = menu.querySelector('.quiz-hud');
          var style = getComputedStyle(hud);
          return {
            radius: parseFloat(style.borderTopLeftRadius),
            left: menu.getBoundingClientRect().left,
            height: hud.getBoundingClientRect().height,
            background: [ style.backgroundColor, style.backgroundImage ].join(' | '),
            packCount: hud.querySelectorAll('.quiz-hud-pack').length
          };
        })()
      JS
    end

    def assert_navigation_affordance!(width:, height:)
      navigation = page.evaluate_script(<<~JS)
        (function() {
          var visible = function(node) {
            if (!node) return false;
            var style = getComputedStyle(node);
            var rect = node.getBoundingClientRect();
            return style.display !== 'none' && style.visibility !== 'hidden' && rect.width >= 44 && rect.height >= 44;
          };
          var dock = document.querySelector('.navigation-dock');
          var nav = document.querySelector('.desktop-navigation');
          return {
            dock: visible(dock) ? {
              position: getComputedStyle(dock).position,
              bottom: dock.getBoundingClientRect().bottom,
              items: dock.querySelectorAll('.navigation-dock__item').length
            } : null,
            nav: visible(nav),
            navLinks: nav && visible(nav) ? Array.from(nav.querySelectorAll('a')).map(function(link) {
              var style = getComputedStyle(link);
              var box = link.getBoundingClientRect();
              return { height: box.height, fontSize: parseFloat(style.fontSize) };
            }) : []
          };
        })()
      JS

      if width < DESKTOP_WIDTH
        assert navigation.fetch("dock"), navigation.inspect
        assert_equal "fixed", navigation.dig("dock", "position"), navigation.inspect
        assert_equal 5, navigation.dig("dock", "items"), navigation.inspect
        assert_operator navigation.dig("dock", "bottom"), :<=, height + 1, navigation.inspect
        refute navigation.fetch("nav"), navigation.inspect
      else
        assert_nil navigation.fetch("dock"), navigation.inspect
        assert navigation.fetch("nav"), navigation.inspect
        assert navigation.fetch("navLinks").all? { |link| link.fetch("height") >= 44 && link.fetch("fontSize") >= 16 }, navigation.inspect
        assert_selector ".desktop-navigation a[aria-current='page']", text: I18n.t("hub.nav_home", locale: :fr)
      end
    end

    def assert_long_hero_copy_does_not_collide!(theme:, width:, height:)
      original = page.evaluate_script(<<~JS)
        (function() {
          var title = document.querySelector('.hub-hero-title');
          var lede = document.querySelector('.hub-hero-lede');
          return { title: title.textContent, lede: lede.textContent };
        })()
      JS
      page.execute_script(<<~JS)
        document.querySelector('.hub-hero-title').textContent = 'LA VIE DU SAUVEUR';
        document.querySelector('.hub-hero-lede').textContent = 'Bethléem, le baptême, les miracles : Jésus parmi nous.';
      JS
      geometry = page.evaluate_script(<<~JS)
        (function() {
          var copy = document.querySelector('.hub-slide-copy-top').getBoundingClientRect();
          var actions = document.querySelector('.hub-hero-actions').getBoundingClientRect();
          var stage = document.querySelector('.hub-hero-stage').getBoundingClientRect();
          return { gap: actions.top - copy.bottom, copyTop: copy.top, actionsBottom: actions.bottom, stageTop: stage.top, stageBottom: stage.bottom };
        })()
      JS
      assert_operator geometry.fetch("gap"), :>=, width <= 390 ? 8 : 16, { theme:, width:, height:, geometry: }.inspect
      assert_operator geometry.fetch("copyTop"), :>=, geometry.fetch("stageTop"), geometry.inspect
      assert_operator geometry.fetch("actionsBottom"), :<=, geometry.fetch("stageBottom") + 1, geometry.inspect
    ensure
      if original
        page.execute_script(<<~JS, original.fetch("title"), original.fetch("lede"))
          document.querySelector('.hub-hero-title').textContent = arguments[0];
          document.querySelector('.hub-hero-lede').textContent = arguments[1];
        JS
      end
    end

    def card_geometry(card)
      page.evaluate_script(<<~JS, card.native)
        (function(card) {
          var rect = card.getBoundingClientRect();
          return {
            top: rect.top,
            border: getComputedStyle(card).borderTopColor,
            transform: getComputedStyle(card).transform
          };
        })(arguments[0])
      JS
    end

    def shot_block(selector, name)
      page.execute_script("document.querySelector(#{selector.to_json}).scrollIntoView({ block: 'center', behavior: 'auto' })")
      page.driver.browser.execute_async_script("window.setTimeout(arguments[0], 60)")
      shot(name)
    end

    def shot(name)
      FileUtils.mkdir_p(SHOT_DIR)
      page.save_screenshot(SHOT_DIR.join("#{name}.png"))
    end

    def severe_browser_logs
      page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
    end
end
