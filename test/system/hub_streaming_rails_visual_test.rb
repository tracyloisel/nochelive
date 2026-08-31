require "application_system_test_case"

class HubStreamingRailsVisualTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/street-shots/temple-mockups")
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
    @ward.update!(scripture_circle_mode: "active")
    @week = create_current_weekly_program!
    @question = seed_quiz_reading!
    seed_recent_gain!
    seed_circle_activity!
    seed_published_event!
    sign_in_fixture_person_direct!(@person)
    page.driver.browser.manage.add_cookie(name: Locale::COOKIE.to_s, value: "fr", path: "/")
  end

  test "the Hub keeps a cinematic Hero followed by one horizontal Rama rail in both celestial families" do
    theme_worlds.each do |theme, world|
      Hubs::Backdrop.entries = [ world ]

      VIEWPORTS.each do |width, height|
        set_system_viewport(width, height)
        visit root_path

        assert_selector "html[lang='fr']"
        assert_selector "#street_world[data-hub-theme='#{theme}']"
        assert_editorial_structure!
        assert_editorial_geometry!(width:, height:)
        assert_long_hero_copy_does_not_collide!(theme:, width:, height:) if [ 320, 390, 768, 1024, 1440 ].include?(width)
        assert_mobile_hero_tableau!(width:, height:) if width <= 390
        assert_mobile_hero_clearance!(width:, height:) if width <= 390
        assert_rama_rail_geometry!(width:) if width <= 390
        assert_navigation_affordance!(width:)
        assert_empty severe_browser_logs, "Hub console errors at #{theme} #{width}x#{height}: #{severe_browser_logs.inspect}"

        if [ 320, 390, 768, 1440 ].include?(width)
          page.execute_script("window.scrollTo(0, 0)")
          shot("hub-editorial-#{theme}-#{width}x#{height}-top")
        end
        shot_block(".hub-now", "hub-editorial-#{theme}-#{width}x#{height}-now") if [ 390, 1440 ].include?(width)
        shot_block(".hub-rama-carousel", "hub-editorial-#{theme}-#{width}x#{height}-rama") if [ 390, 1440 ].include?(width)
        if [ 390, 1440 ].include?(width)
          page.execute_script("document.querySelector('.hub-rama-card--challenge').scrollIntoView({ inline: 'start', block: 'nearest' })")
          shot_block(".hub-rama-carousel", "hub-editorial-#{theme}-#{width}x#{height}-rama-utilities")
        end
      end
    end
  ensure
    Hubs::Backdrop.reset!
  end

  test "chapter status, focus, reduced motion, and forced colors stay readable beside the static Rama rail" do
    Hubs::Backdrop.entries = [ theme_worlds.fetch("dark") ]
    set_system_viewport(1440, 900)
    visit root_path

    circle = find(".hub-rama-card--circle")
    page.execute_script("arguments[0].scrollIntoView({ inline: 'center', block: 'nearest' })", circle.native)
    hover_before = page.evaluate_script(<<~JS)
      (function() {
        var card = document.querySelector('.hub-rama-card--circle');
        var rect = card.getBoundingClientRect();
        return { top: rect.top, border: getComputedStyle(card).borderTopColor };
      })()
    JS
    circle.hover
    hover_after = page.evaluate_script(<<~JS)
      (function() {
        var card = document.querySelector('.hub-rama-card--circle');
        var rect = card.getBoundingClientRect();
        return { top: rect.top, border: getComputedStyle(card).borderTopColor };
      })()
    JS
    assert_in_delta hover_before.fetch("top"), hover_after.fetch("top"), 0.5, { before: hover_before, after: hover_after }.inspect
    refute_equal hover_before.fetch("border"), hover_after.fetch("border"), { before: hover_before, after: hover_after }.inspect

    assert_selector ".hub-now-card.is-in_progress .hub-now-card__status", text: I18n.t("hub.rails.reading_in_progress", percent: 42, locale: :fr)
    assert_selector ".hub-now-card.is-in_progress .hub-now-card__meter i[style*='42%']"
    assert_no_selector ".hub-now-card .hub-now-card__status a, .hub-now-card .hub-now-card__status button"

    page.execute_script("document.querySelector('.hub-now-card--reading').focus()")
    focus = page.evaluate_script(<<~JS)
      (function() {
        var card = document.querySelector('.hub-now-card--reading');
        var style = getComputedStyle(card);
        return { active: document.activeElement === card, outline: style.outlineStyle };
      })()
    JS
    assert focus.fetch("active"), focus.inspect
    assert_equal "solid", focus.fetch("outline"), focus.inspect
    assert_voyage_controls!

    page.driver.browser.execute_cdp(
      "Emulation.setEmulatedMedia",
      features: [ { name: "prefers-reduced-motion", value: "reduce" } ]
    )
    visit root_path
    motion = page.evaluate_script(<<~JS)
      (function() {
        var card = document.querySelector('.hub-now-card');
        var live = document.querySelector('.hub-live--feature');
        return {
          cardTransition: getComputedStyle(card).transitionDuration,
          liveAnimation: getComputedStyle(live).animationName
        };
      })()
    JS
    assert_includes motion.fetch("cardTransition").split(","), "0s"
    assert_equal "none", motion.fetch("liveAnimation")

    page.driver.browser.execute_cdp(
      "Emulation.setEmulatedMedia",
      features: [ { name: "forced-colors", value: "active" } ]
    )
    set_system_viewport(390, 844)
    visit root_path
    forced = page.evaluate_script(<<~JS)
      (function() {
        var card = document.querySelector('.hub-now-card');
        var art = card.querySelector('.hub-now-card__art');
        var scrim = card.querySelector('.hub-now-card__scrim');
        var style = getComputedStyle(card);
        return {
          overflow: document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
          artHidden: !art || getComputedStyle(art).display === 'none',
          scrimHidden: getComputedStyle(scrim).display === 'none',
          contrast: style.backgroundColor !== style.color
        };
      })()
    JS
    assert_not forced.fetch("overflow"), forced.inspect
    assert forced.fetch("artHidden"), forced.inspect
    assert forced.fetch("scrimHidden"), forced.inspect
    assert forced.fetch("contrast"), forced.inspect
    shot("hub-editorial-dark-390x844-forced-colors")
    assert_empty severe_browser_logs
  ensure
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: []) rescue nil
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

    def create_current_weekly_program!
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
      content = YAML.safe_load_file(Rails.root.join("config/study/come_follow_me_2026.yml")).dig("quizzes", 0, "content")
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

    def assert_editorial_structure!
      snapshot = page.evaluate_script(<<~JS)
        (function() {
          var feed = document.querySelector('.street-hub-feed');
          var direct = function(className) {
            return Array.from(feed ? feed.children : []).filter(function(node) { return node.classList.contains(className); }).length;
          };
          var hrefCount = function(className, href) {
            return Array.from(feed ? feed.querySelectorAll('.' + className) : []).filter(function(node) {
              return node.getAttribute('href') === href;
            }).length;
          };
          var visibleLink = function(selector, href) {
            var node = feed && feed.querySelector(selector);
            if (!node || node.getAttribute('href') !== href) return false;
            var style = getComputedStyle(node);
            var rect = node.getBoundingClientRect();
            return !node.hidden && style.display !== 'none' && style.visibility !== 'hidden' && rect.width >= 44 && rect.height >= 44;
          };
          return {
            editorial: feed && feed.classList.contains('hub-streaming-feed--editorial'),
            layout: feed && feed.getAttribute('data-hub-layout'),
            hero: direct('hub-hero'),
            heroVoyage: Boolean(feed && feed.querySelector('.hub-hero[data-controller~="hub-voyage"]')),
            carousel: direct('hub-rama-carousel'),
            carouselTrack: Boolean(feed && feed.querySelector(':scope > .hub-rama-carousel > .hub-rama-carousel__track[role="list"]')),
            carouselCards: feed ? feed.querySelectorAll(':scope > .hub-rama-carousel > .hub-rama-carousel__track > .hub-rama-card[role="listitem"]').length : -1,
            live: feed ? feed.querySelectorAll(':scope > .hub-rama-carousel .hub-rama-card--live > .hub-live--feature').length : -1,
            now: direct('hub-now'),
            install: direct('hub-install--compact'),
            identityEmpty: direct('hub-identity-empty'),
            quickActions: direct('hub-quick-actions'),
            challengesVisible: visibleLink(':scope > .hub-rama-carousel .hub-rama-card--challenge', #{street_challenges_path.to_json}),
            videosVisible: visibleLink(':scope > .hub-rama-carousel .hub-rama-card--videos', #{church_videos_path(locale: :fr).to_json}),
            reading: hrefCount('hub-now-card', #{scripture_path(@question.scripture.study, cite: @question.scripture.cite).to_json}),
            programme: hrefCount('hub-now__programme', #{scripture_library_path(section: "weekly", unit: @week.id, anchor: "selection").to_json}),
            circle: hrefCount('hub-rama-card--circle', #{scripture_circle_path.to_json}),
            heroPlay: feed ? feed.querySelectorAll('.hub-hero .hub-play').length : -1,
            legacyHeroPlay: feed ? feed.querySelectorAll('.hub-hero .btn.btn-gold').length : -1,
            installImmediatelyAfterCarousel: Boolean(feed && feed.querySelector(':scope > .hub-rama-carousel + .hub-install--compact')),
            nowAfterInstall: Boolean(feed && feed.querySelector(':scope > .hub-install--compact + .hub-now'))
          };
        })()
      JS

      assert snapshot.fetch("editorial"), snapshot.inspect
      assert_equal "hero-rama-carousel", snapshot.fetch("layout"), snapshot.inspect
      assert_equal 1, snapshot.fetch("hero"), snapshot.inspect
      assert snapshot.fetch("heroVoyage"), snapshot.inspect
      assert_equal 1, snapshot.fetch("carousel"), snapshot.inspect
      assert snapshot.fetch("carouselTrack"), snapshot.inspect
      assert_operator snapshot.fetch("carouselCards"), :>=, 3, snapshot.inspect
      assert_equal 1, snapshot.fetch("live"), snapshot.inspect
      assert_equal 1, snapshot.fetch("now"), snapshot.inspect
      assert_equal 1, snapshot.fetch("install"), snapshot.inspect
      assert_equal 0, snapshot.fetch("identityEmpty"), snapshot.inspect
      assert_equal 0, snapshot.fetch("quickActions"), snapshot.inspect
      assert snapshot.fetch("challengesVisible"), snapshot.inspect
      assert snapshot.fetch("videosVisible"), snapshot.inspect
      assert_equal 1, snapshot.fetch("reading"), snapshot.inspect
      assert_equal 1, snapshot.fetch("programme"), snapshot.inspect
      assert_equal 1, snapshot.fetch("circle"), snapshot.inspect
      assert_equal 1, snapshot.fetch("heroPlay"), snapshot.inspect
      assert_equal 0, snapshot.fetch("legacyHeroPlay"), snapshot.inspect
      assert snapshot.fetch("installImmediatelyAfterCarousel"), snapshot.inspect
      assert snapshot.fetch("nowAfterInstall"), snapshot.inspect
    end

    def assert_editorial_geometry!(width:, height:)
      geometry = page.evaluate_script(<<~JS)
        (function() {
          var visible = function(element) {
            var style = getComputedStyle(element);
            var rect = element.getBoundingClientRect();
            return !element.hidden && style.display !== 'none' && style.visibility !== 'hidden' &&
              rect.width > 0 && rect.height > 0;
          };
          var rect = function(node) {
            var value = node.getBoundingClientRect();
            return {
              left: value.left, right: value.right, top: value.top, bottom: value.bottom,
              width: value.width, height: value.height
            };
          };
          var copy = Array.from(document.querySelectorAll('.hub-hero .hub-slide.is-current .hub-hero-title, .hub-hero .hub-slide.is-current .hub-hero-name, .hub-hero .hub-slide.is-current .hub-hero-lede, .hub-hero .hub-slide.is-current .hub-reward-value, .hub-rama-card strong, .hub-rama-card span, .hub-rama-card p, .hub-now strong, .hub-now span')).filter(visible);
          var targets = Array.from(document.querySelectorAll('.hub-hero .hub-dot, .hub-hero .hub-play, .hub-rama-card a, a.hub-rama-card, .hub-rama-card button, .hub-now a, .hub-now button')).filter(visible);
          var feed = document.querySelector('.street-hub-feed');
          var now = document.querySelector('.hub-now__grid');
          var carousel = document.querySelector('.hub-rama-carousel');
          var track = document.querySelector('.hub-rama-carousel__track');
          var cards = Array.from(document.querySelectorAll('.hub-rama-carousel__track > .hub-rama-card'));
          var dock = document.querySelector('.navigation-dock');
          var hud = document.querySelector('body > .home-menu.is-hud');
          var nav = document.querySelector('.hub-desktop-navigation');
          var stage = document.querySelector('.hub-hero-stage');
          var currentMark = document.querySelector('.hub-slide.is-current .hub-hero-worldmark');
          var heroElement = document.querySelector('.hub-hero');
          var currentStill = document.querySelector('.hub-slide.is-current .hub-slide-still');
          var dots = document.querySelector('.hub-hero .hub-dots');
          var progress = document.querySelector('.hub-slide.is-current .hub-hero-progress');
          var play = document.querySelector('.hub-slide.is-current .hub-play');
          var league = document.querySelector('.hub-slide.is-current .hub-hero-league');
          var gains = document.querySelector('.hub-slide.is-current .hub-hero-gains');
          var voyageNav = document.querySelector('.hub-voyage-nav');
          var voyageStyle = voyageNav && getComputedStyle(voyageNav);
          var dockRect = dock && visible(dock) ? dock.getBoundingClientRect() : null;
          return {
            overflow: document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
            order: Array.from(feed.children).filter(function(node) {
              return node.matches('.hub-hero, .hub-rama-carousel, .hub-install--compact, .hub-now');
            }).map(function(node) {
              if (node.matches('.hub-hero')) return 'hero';
              if (node.matches('.hub-rama-carousel')) return 'carousel';
              if (node.matches('.hub-install--compact')) return 'install';
              return 'now';
            }),
            nowColumns: getComputedStyle(now).gridTemplateColumns.split(' ').filter(Boolean).length,
            /* Some display faces intentionally overhang their line boxes. A
               genuine defect is paint leaving its own story card, not a
               one-pixel typographic descender reported by scrollHeight. */
            clipped: copy.filter(function(node) {
              var rect = node.getBoundingClientRect();
              var container = node.closest('.hub-hero-stage, .hub-rama-card, .hub-now');
              var bounds = container && container.getBoundingClientRect();
              return bounds && (
                rect.left < bounds.left - 2 || rect.right > bounds.right + 2 ||
                rect.top < bounds.top - 2 || rect.bottom > bounds.bottom + 2
              );
            }).map(function(node) { return node.textContent.trim(); }),
            targets: targets.map(function(node) {
              var rect = node.getBoundingClientRect();
              return { width: rect.width, height: rect.height };
            }),
            dock: dock && visible(dock) ? {
              position: getComputedStyle(dock).position,
              bottom: dockRect.bottom,
              top: dockRect.top,
              itemCount: dock.querySelectorAll('.navigation-dock__item').length,
              outsideFeed: !feed.contains(dock)
            } : null,
            hudOutsideFeed: Boolean(hud && !feed.contains(hud)),
            nav: nav && visible(nav),
            cockpit: progress && play ? {
              progress: rect(progress),
              play: rect(play),
              leagueVisible: Boolean(league && visible(league)),
              gainsVisible: Boolean(gains && visible(gains))
            } : null,
            hero: stage ? {
              height: stage.getBoundingClientRect().height,
              bottom: stage.getBoundingClientRect().bottom,
              safeArt: heroElement && [
                'hub.hero.salt-lake-temple-night',
                'hub.hero.salt-lake-temple-dawn'
              ].includes(heroElement.dataset.hubHeroArt),
              stillTop: currentStill ? currentStill.getBoundingClientRect().top : null,
              hudBottom: hud ? hud.getBoundingClientRect().bottom : null,
              worldmarkVisible: currentMark && visible(currentMark),
              dotsBottom: dots ? dots.getBoundingClientRect().bottom : null,
              voyageNav: voyageNav && visible(voyageNav) ? rect(voyageNav) : null,
              voyageChrome: voyageStyle ? {
                background: voyageStyle.backgroundColor,
                border: voyageStyle.borderTopWidth,
                shadow: voyageStyle.boxShadow,
                backdrop: voyageStyle.backdropFilter || voyageStyle.webkitBackdropFilter
              } : null,
              voyageDots: voyageNav ? voyageNav.querySelectorAll('.hub-dot').length : 0
            } : null,
            carousel: carousel && track ? {
              top: carousel.getBoundingClientRect().top,
              width: carousel.getBoundingClientRect().width,
              overflowX: getComputedStyle(track).overflowX,
              trackBottom: track.getBoundingClientRect().bottom,
              clientWidth: track.clientWidth,
              scrollWidth: track.scrollWidth,
              cards: cards.map(function(card) {
                var box = rect(card);
                box.borderBottomWidth = getComputedStyle(card).borderBottomWidth;
                box.borderBottomColor = getComputedStyle(card).borderBottomColor;
                return box;
              })
            } : null
          };
        })()
      JS

      assert_not geometry.fetch("overflow"), geometry.inspect
      assert_equal %w[hero carousel install now], geometry.fetch("order"), geometry.inspect
      assert_equal 1, geometry.fetch("nowColumns"), geometry.inspect
      assert_empty geometry.fetch("clipped"), geometry.inspect
      assert geometry.fetch("targets").all? { |target| target.fetch("width") >= 44 && target.fetch("height") >= 44 }, geometry.inspect
      assert geometry.fetch("hudOutsideFeed"), geometry.inspect
      assert geometry.fetch("carousel"), geometry.inspect
      assert geometry.fetch("cockpit"), geometry.inspect
      assert geometry.dig("hero", "voyageNav"), geometry.inspect
      assert_operator geometry.dig("hero", "voyageDots"), :>=, 2, geometry.inspect
      assert_equal "rgba(0, 0, 0, 0)", geometry.dig("hero", "voyageChrome", "background"), geometry.inspect
      assert_equal "0px", geometry.dig("hero", "voyageChrome", "border"), geometry.inspect
      assert_equal "none", geometry.dig("hero", "voyageChrome", "shadow"), geometry.inspect
      assert_equal "none", geometry.dig("hero", "voyageChrome", "backdrop"), geometry.inspect
      assert_no_selector ".hub-voyage-nav__button, .hub-voyage-nav__count"
      assert geometry.dig("cockpit", "leagueVisible"), geometry.inspect
      if width <= 360
        refute geometry.dig("cockpit", "gainsVisible"), geometry.inspect
      else
        assert geometry.dig("cockpit", "gainsVisible"), geometry.inspect
      end
      assert_operator geometry.dig("carousel", "cards").length, :>=, 3, geometry.inspect
      assert geometry.dig("carousel", "cards").all? { |card|
        card.fetch("borderBottomWidth").to_f >= 1 && card.fetch("borderBottomColor") != "rgba(0, 0, 0, 0)" &&
          card.fetch("bottom") <= geometry.dig("carousel", "trackBottom") - 8
      }, geometry.inspect
      if width >= 768 && geometry.dig("hero", "safeArt")
        assert_operator geometry.dig("hero", "stillTop"), :>=, geometry.dig("hero", "hudBottom") - 1, geometry.inspect
      end
      card_tops = geometry.dig("carousel", "cards").map { |card| card.fetch("top") }
      assert card_tops.all? { |top| (top - card_tops.first).abs <= 2 }, geometry.inspect
      if width < DESKTOP_WIDTH
        assert_in_delta geometry.dig("hero", "bottom"), geometry.dig("carousel", "top"), 2, geometry.inspect
      else
        # The desktop mockup keeps the full-bleed painting behind the Rama
        # rail; the richer competitive cockpit now owns a little more of the
        # opening tableau before the horizontal community deck begins.
        assert_operator geometry.dig("carousel", "top"), :<, geometry.dig("hero", "bottom"), geometry.inspect
        assert_in_delta height * 0.585, geometry.dig("carousel", "top"), 3, geometry.inspect
        assert_in_delta geometry.dig("cockpit", "progress", "top"), geometry.dig("cockpit", "play", "top"), 1, geometry.inspect
        assert_in_delta geometry.dig("cockpit", "progress", "height"), geometry.dig("cockpit", "play", "height"), 1, geometry.inspect
      end

      if width < DESKTOP_WIDTH
        assert geometry.fetch("dock"), geometry.inspect
        assert_equal "fixed", geometry.dig("dock", "position"), geometry.inspect
        assert_equal 5, geometry.dig("dock", "itemCount"), geometry.inspect
        assert geometry.dig("dock", "outsideFeed"), geometry.inspect
        assert_operator geometry.dig("dock", "bottom"), :<=, height + 1, geometry.inspect
        refute geometry.fetch("nav"), geometry.inspect
      else
        assert_nil geometry.fetch("dock"), geometry.inspect
        assert geometry.fetch("nav"), geometry.inspect
      end

      if width < DESKTOP_WIDTH
        refute geometry.dig("hero", "worldmarkVisible"), geometry.inspect
        assert_operator geometry.dig("hero", "dotsBottom"), :<=, geometry.dig("dock", "top") + 1, geometry.inspect
      else
        refute geometry.dig("hero", "worldmarkVisible"), geometry.inspect
      end
    end

    def assert_navigation_affordance!(width:)
      if width < DESKTOP_WIDTH
        assert_no_selector ".hub-desktop-navigation", visible: true
      else
        assert_selector ".hub-desktop-navigation a[aria-current='page']", text: I18n.t("hub.nav_home", locale: :fr)
      end
    end

    def assert_long_hero_copy_does_not_collide!(theme:, width:, height:)
      original = page.evaluate_script(<<~JS)
        (function() {
          var slide = document.querySelector('.hub-slide.is-current');
          var title = slide && slide.querySelector('.hub-hero-title');
          var lede = slide && slide.querySelector('.hub-hero-lede');
          return { title: title && title.textContent, lede: lede && lede.textContent };
        })()
      JS

      page.execute_script(<<~JS)
        (function() {
          var slide = document.querySelector('.hub-slide.is-current');
          slide.querySelector('.hub-hero-title').textContent = 'LA VIE DU SAUVEUR';
          slide.querySelector('.hub-hero-lede').textContent = 'Bethléem, le baptême, les miracles : Jésus parmi nous.';
        })()
      JS

      geometry = page.evaluate_script(<<~JS)
        (function() {
          var slide = document.querySelector('.hub-slide.is-current');
          var copy = slide.querySelector('.hub-slide-copy-top').getBoundingClientRect();
          var actions = slide.querySelector('.hub-hero-actions').getBoundingClientRect();
          var stage = slide.closest('.hub-hero-stage').getBoundingClientRect();
          var titleNode = slide.querySelector('.hub-hero-title');
          var title = titleNode.getBoundingClientRect();
          var titleRange = document.createRange();
          titleRange.selectNodeContents(titleNode);
          var titleLines = Array.from(titleRange.getClientRects()).reduce(function(tops, line) {
            if (!tops.some(function(top) { return Math.abs(top - line.top) < 1; })) tops.push(line.top);
            return tops;
          }, []);
          return {
            gap: actions.top - copy.bottom,
            copyTop: copy.top,
            actionsBottom: actions.bottom,
            stageTop: stage.top,
            stageBottom: stage.bottom,
            titleHeight: title.height,
            titleLines: titleLines.length
          };
        })()
      JS

      assert_operator geometry.fetch("gap"), :>=, width <= 390 ? 8 : 16, { theme:, width:, height:, geometry: }.inspect
      assert_operator geometry.fetch("copyTop"), :>=, geometry.fetch("stageTop"), { theme:, width:, height:, geometry: }.inspect
      assert_operator geometry.fetch("actionsBottom"), :<=, geometry.fetch("stageBottom") + 1, { theme:, width:, height:, geometry: }.inspect
      assert_operator geometry.fetch("titleLines"), :<=, width <= 320 ? 3 : 2, { theme:, width:, height:, geometry: }.inspect
      shot("hub-editorial-#{theme}-#{width}x#{height}-long-hero-copy")
    ensure
      if original
        page.execute_script(<<~JS, original.fetch("title"), original.fetch("lede"))
          (function(titleText, ledeText) {
            var slide = document.querySelector('.hub-slide.is-current');
            if (!slide) return;
            var title = slide.querySelector('.hub-hero-title');
            var lede = slide.querySelector('.hub-hero-lede');
            if (title) title.textContent = titleText;
            if (lede) lede.textContent = ledeText;
          })(arguments[0], arguments[1])
        JS
      end
    end

    def assert_voyage_controls!
      dots = all(".hub-voyage-nav .hub-dot")
      assert_operator dots.length, :>=, 2
      original = find(".hub-voyage-nav .hub-dot[aria-current='true']")["data-index"].to_i
      destination = original.zero? ? 1 : 0
      assert_voyage_slides_are_isolated!(current_index: original)

      dots[destination].click
      assert_selector ".hub-voyage-nav .hub-dot[data-index='#{destination}'][aria-current='true']"
      assert_voyage_slides_are_isolated!(current_index: destination)

      all(".hub-voyage-nav .hub-dot")[original].click
      assert_selector ".hub-voyage-nav .hub-dot[data-index='#{original}'][aria-current='true']"
      assert_voyage_slides_are_isolated!(current_index: original)
      assert_no_selector ".hub-voyage-nav__button, .hub-voyage-nav__count"
    end

    def assert_voyage_slides_are_isolated!(current_index:)
      isolation = page.evaluate_script(<<~JS)
        (function() {
          var selectors = [
            'a[href]:not([disabled])',
            'button:not([disabled])',
            'input:not([disabled])',
            'select:not([disabled])',
            'textarea:not([disabled])',
            '[tabindex]:not([tabindex="-1"])'
          ].join(',');
          var canReceiveFocus = function(node) {
            try {
              node.focus({ preventScroll: true });
            } catch (error) {
              node.focus();
            }
            return document.activeElement === node;
          };

          var slides = Array.from(document.querySelectorAll('.hub-voyage .hub-slide'));
          return slides.map(function(slide, index) {
            var controls = Array.from(slide.querySelectorAll(selectors));
            return {
              index: index,
              current: slide.classList.contains('is-current'),
              inert: slide.hasAttribute('inert'),
              ariaHidden: slide.getAttribute('aria-hidden'),
              controlCount: controls.length,
              programmaticFocus: controls.map(canReceiveFocus)
            };
          });
        })()
      JS

      assert_operator isolation.length, :>=, 2, isolation.inspect
      active = isolation.find { |slide| slide.fetch("current") }
      assert active, isolation.inspect
      assert_equal current_index, active.fetch("index"), isolation.inspect
      refute active.fetch("inert"), isolation.inspect
      assert_equal "false", active.fetch("ariaHidden"), isolation.inspect
      assert active.fetch("programmaticFocus").any?, isolation.inspect if active.fetch("controlCount").positive?

      inactive = isolation.reject { |slide| slide.fetch("current") }
      assert inactive.all? { |slide|
        slide.fetch("inert") && slide.fetch("ariaHidden") == "true" && slide.fetch("programmaticFocus").none?
      }, isolation.inspect
      assert_operator isolation.sum { |slide| slide.fetch("controlCount") }, :>=, 1, isolation.inspect
    end

    # The mobile Hero is a fixed opening tableau, not a viewport-height reel.
    # The existing HUD overlays it without consuming layout height; the Rama
    # section begins immediately after the approximately 364px painting.
    def assert_mobile_hero_tableau!(width:, height:)
      tableau = page.evaluate_script(<<~JS)
        (function() {
          var rect = function(node) {
            if (!node) return null;
            var value = node.getBoundingClientRect();
            return {
              left: value.left, right: value.right, top: value.top, bottom: value.bottom,
              width: value.width, height: value.height
            };
          };
          var stage = document.querySelector('.hub-hero-stage');
          var still = document.querySelector('.hub-slide.is-current .hub-slide-still');
          var play = document.querySelector('.hub-slide.is-current .hub-play');
          var reward = document.querySelector('.hub-slide.is-current .hub-reward');
          var dock = document.querySelector('.navigation-dock');
          var hud = document.querySelector('body > .home-menu.is-hud');
          var style = stage && getComputedStyle(stage);
          return {
            stage: rect(stage),
            still: rect(still),
            play: rect(play),
            reward: reward && reward.getBoundingClientRect().width > 0 && reward.getBoundingClientRect().height > 0 ? rect(reward) : null,
            dock: rect(dock),
            hud: rect(hud),
            stageSurface: style && {
              borderTopWidth: style.borderTopWidth,
              borderTopLeftRadius: style.borderTopLeftRadius,
              boxShadow: style.boxShadow
            }
          };
        })()
      JS

      assert tableau.fetch("stage"), tableau.inspect
      assert tableau.fetch("still"), tableau.inspect
      assert tableau.fetch("play"), tableau.inspect
      assert tableau.fetch("dock"), tableau.inspect
      assert tableau.fetch("hud"), tableau.inspect
      assert_equal "0px", tableau.dig("stageSurface", "borderTopWidth"), tableau.inspect
      assert_in_delta 0, tableau.dig("stageSurface", "borderTopLeftRadius").delete_suffix("px").to_f, 0.1, tableau.inspect
      assert_equal "none", tableau.dig("stageSurface", "boxShadow"), tableau.inspect
      assert_operator tableau.dig("stage", "left"), :<=, 1, tableau.inspect
      assert_operator tableau.dig("stage", "right"), :>=, width - 1, tableau.inspect
      assert_operator tableau.dig("stage", "top"), :<=, 1, tableau.inspect
      assert_operator tableau.dig("still", "left"), :<=, 1, tableau.inspect
      assert_operator tableau.dig("still", "right"), :>=, width - 1, tableau.inspect
      assert_operator tableau.dig("still", "top"), :<=, 1, tableau.inspect
      assert_operator tableau.dig("still", "bottom"), :>=, tableau.dig("stage", "bottom") - 1, tableau.inspect
      assert_operator tableau.dig("play", "height"), :>=, 44, tableau.inspect
      assert_operator tableau.dig("play", "width"), :>=, width * 0.5, tableau.inspect
      assert_operator tableau.dig("play", "bottom"), :<=, tableau.dig("dock", "top") - 12, tableau.inspect
      assert_operator tableau.dig("hud", "bottom"), :<=, tableau.dig("play", "top"), tableau.inspect

      assert_operator tableau.dig("stage", "height"), :>=, height * 0.7, tableau.inspect

      if tableau.fetch("reward")
        assert_operator tableau.dig("reward", "top"), :>=, tableau.dig("play", "bottom") + 8, tableau.inspect
      end
    end

    def assert_mobile_hero_clearance!(width:, height:)
      clearance = page.evaluate_script(<<~JS)
        (function() {
          var visible = function(node) {
            if (!node) return false;
            var style = getComputedStyle(node);
            var box = node.getBoundingClientRect();
            return !node.hidden && style.display !== 'none' && style.visibility !== 'hidden' &&
              box.width > 0 && box.height > 0;
          };
          var rect = function(node) {
            if (!node) return null;
            var box = node.getBoundingClientRect();
            return {
              left: box.left, right: box.right, top: box.top, bottom: box.bottom,
              width: box.width, height: box.height
            };
          };
          var overlaps = function(first, second, tolerance) {
            if (!first || !second) return false;
            var gap = tolerance || 1;
            return first.left < second.right - gap && first.right > second.left + gap &&
              first.top < second.bottom - gap && first.bottom > second.top + gap;
          };
          var current = document.querySelector('.hub-slide.is-current');
          var copy = current && current.querySelector('.hub-slide-copy-top');
          var actions = current && current.querySelector('.hub-hero-actions');
          var title = current && current.querySelector('.hub-hero-title');
          var hud = document.querySelector('body > .home-menu.is-hud');
          var dock = document.querySelector('.navigation-dock');
          var dots = document.querySelector('.hub-voyage-nav');
          var importantText = [
            [ 'hero title', title ],
            [ 'hero pack', current && current.querySelector('.hub-hero-name') ],
            [ 'hero progress', current && current.querySelector('.hub-hero-progress__label') ],
            [ 'league rank', current && current.querySelector('.hub-hero-league__copy b') ],
            [ 'league detail', current && current.querySelector('.hub-hero-league__copy small') ]
          ].concat(
            Array.from(document.querySelectorAll('.hub-rama-carousel__track > .hub-rama-card strong, .hub-rama-carousel__track > .hub-rama-card .hub-rama-event__kicker')).map(function(node) {
              return [ 'Rama card', node ];
            })
          ).concat(
            dock ? Array.from(dock.querySelectorAll('.navigation-dock__item > span:last-child')).map(function(node) {
              return [ 'dock label', node ];
            }) : []
          ).filter(function(entry) {
            return visible(entry[1]) && entry[1].textContent.trim().length > 0;
          }).map(function(entry) {
            var node = entry[1];
            var style = getComputedStyle(node);
            return {
              label: entry[0],
              text: node.textContent.trim(),
              clippedX: node.scrollWidth > node.clientWidth + 1 && /hidden|clip/.test(style.overflowX),
              clippedY: node.scrollHeight > node.clientHeight + 1 && /hidden|clip/.test(style.overflowY)
            };
          });
          var dockLabels = dock ? Array.from(dock.querySelectorAll('.navigation-dock__item > span:last-child')).filter(visible).map(rect) : [];
          var dockLabelOverlaps = dockLabels.some(function(label, index) {
            return dockLabels.slice(index + 1).some(function(next) { return overlaps(label, next); });
          });

          return {
            hudCopyOverlap: overlaps(rect(hud), rect(copy)),
            hudTitleOverlap: overlaps(rect(hud), rect(title)),
            hudActionsOverlap: overlaps(rect(hud), rect(actions)),
            copyActionsOverlap: overlaps(rect(copy), rect(actions)),
            actionsDockOverlap: overlaps(rect(actions), rect(dock)),
            dotsActionsOverlap: overlaps(rect(dots), rect(actions)),
            dotsDockOverlap: overlaps(rect(dots), rect(dock)),
            dockLabelOverlaps: dockLabelOverlaps,
            text: importantText
          };
        })()
      JS

      assert_not clearance.fetch("hudCopyOverlap"), { width:, height:, clearance: }.inspect
      assert_not clearance.fetch("hudTitleOverlap"), { width:, height:, clearance: }.inspect
      assert_not clearance.fetch("hudActionsOverlap"), { width:, height:, clearance: }.inspect
      assert_not clearance.fetch("copyActionsOverlap"), { width:, height:, clearance: }.inspect
      assert_not clearance.fetch("actionsDockOverlap"), { width:, height:, clearance: }.inspect
      assert_not clearance.fetch("dotsActionsOverlap"), { width:, height:, clearance: }.inspect
      assert_not clearance.fetch("dotsDockOverlap"), { width:, height:, clearance: }.inspect
      assert_not clearance.fetch("dockLabelOverlaps"), { width:, height:, clearance: }.inspect
      assert clearance.fetch("text").all? { |entry| !entry.fetch("clippedX") && !entry.fetch("clippedY") }, { width:, height:, clearance: }.inspect
    end

    def assert_rama_rail_geometry!(width:)
      rail = page.evaluate_script(<<~JS)
        (function() {
          var track = document.querySelector('.hub-rama-carousel__track');
          var cards = Array.from(track.querySelectorAll(':scope > .hub-rama-card'));
          var rect = function(node) {
            var value = node.getBoundingClientRect();
            return { left: value.left, right: value.right, top: value.top, width: value.width, height: value.height };
          };
          return {
            overflowX: getComputedStyle(track).overflowX,
            clientWidth: track.clientWidth,
            scrollWidth: track.scrollWidth,
            cards: cards.map(rect)
          };
        })()
      JS

      assert_operator rail.fetch("cards").length, :>=, 3, rail.inspect
      first, second = rail.fetch("cards").first(2)
      assert_includes %w[auto scroll], rail.fetch("overflowX"), rail.inspect
      assert_operator rail.fetch("scrollWidth"), :>, rail.fetch("clientWidth") + 24, rail.inspect
      assert_in_delta first.fetch("top"), second.fetch("top"), 2, rail.inspect
      assert_operator first.fetch("left"), :>=, 12, rail.inspect
      assert_operator first.fetch("left"), :<=, 24, rail.inspect
      assert_operator first.fetch("width"), :>=, width * 0.58, rail.inspect
      assert_operator first.fetch("width"), :<=, width * 0.75, rail.inspect
      assert_operator second.fetch("left"), :>, first.fetch("right"), rail.inspect
      assert_operator second.fetch("left"), :<, width - 16, rail.inspect
      assert_operator second.fetch("right"), :>, width + 24, rail.inspect
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
