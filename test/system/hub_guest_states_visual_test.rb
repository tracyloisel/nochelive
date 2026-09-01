require "application_system_test_case"

class HubGuestStatesVisualTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/street-shots/editorial-convergence")
  VIEWPORTS = [ [ 320, 568 ], [ 390, 844 ], [ 768, 1024 ], [ 1024, 768 ], [ 1440, 900 ], [ 1536, 1024 ], [ 1920, 1080 ] ].freeze
  DESKTOP_WIDTH = 1200

  setup do
    page.driver.browser.manage.delete_all_cookies
    visit root_path
    page.driver.browser.manage.add_cookie(name: Locale::COOKIE.to_s, value: "fr", path: "/")
  end

  test "an anonymous visitor gets one invitation to play and one honest story for today" do
    theme_worlds.each do |theme, world|
      Hubs::Backdrop.entries = [ world ]

      VIEWPORTS.each do |width, height|
        set_system_viewport(width, height)
        visit root_path

        assert_selector "#street_world[data-hub-theme='#{theme}']"
        assert_guest_editorial_contract!
        assert_home_geometry!(width:, height:, rama: :missing)
        assert_first_viewport_invitation!(height:) if [ [ 390, 844 ], [ 1440, 900 ] ].include?([ width, height ])
        assert_navigation_truth!(width:, height:)
        shot("hub-guest-editorial-#{theme}-#{width}x#{height}") if [ 390, 768, 1440 ].include?(width)
        logs = severe_browser_logs
        assert_empty logs, "Guest Hub console errors at #{theme} #{width}x#{height}: #{logs.inspect}"
      end
    end
  ensure
    Hubs::Backdrop.reset!
  end

  test "a signed in player without a ward keeps a complete Home and a compact ward invitation" do
    person = sign_in_without_ward_direct!
    assert_nil person.ward

    theme_worlds.each do |theme, world|
      Hubs::Backdrop.entries = [ world ]

      [ [ 390, 844 ], [ 1440, 900 ] ].each do |width, height|
        set_system_viewport(width, height)
        visit root_path

        assert_selector "#street_world[data-hub-theme='#{theme}']"
        assert_selector ".quiz-hud:not(.is-guest)"
        assert_selector ".quiz-hud-who", text: person.given_name
        assert_no_selector ".quiz-hud-score, .quiz-hud-streak"
        assert_selector ".hub-rama-presence--missing", count: 1
        assert_no_selector ".hub-identity-empty"
        assert_guest_editorial_contract!
        assert_home_geometry!(width:, height:, rama: :missing)
        assert_first_viewport_invitation!(height:)
        assert_navigation_truth!(width:, height:)
        shot("hub-player-no-rama-editorial-#{theme}-#{width}x#{height}")
        logs = severe_browser_logs
        assert_empty logs, "No-rama Hub console errors at #{theme} #{width}x#{height}: #{logs.inspect}"
      end
    end
  ensure
    Hubs::Backdrop.reset!
  end

  test "a ward-only session asks for a player below the editorial programme without inventing local activity" do
    sign_in_ward_direct!(wards(:blank))

    theme_worlds.each do |theme, world|
      Hubs::Backdrop.entries = [ world ]

      [ [ 390, 844 ], [ 1440, 900 ] ].each do |width, height|
        set_system_viewport(width, height)
        visit root_path

        assert_selector "#street_world[data-hub-theme='#{theme}']"
        assert_selector ".hub-identity-empty.is-player-missing", count: 1
        assert_no_selector ".hub-rama-presence--missing"
        assert_no_selector ".hub-rama-carousel"
        assert_selector ".hub-identity-empty + .hub-install--compact"
        assert_guest_editorial_contract!(expect_ward_invitation: false)
        assert_home_geometry!(width:, height:, rama: :none)
        assert_navigation_truth!(width:, height:)
        logs = severe_browser_logs
        assert_empty logs, "Ward-only Hub console errors at #{theme} #{width}x#{height}: #{logs.inspect}"
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

    def assert_guest_editorial_contract!(expect_ward_invitation: true)
      assert_selector ".street-hub-feed.hub-streaming-feed--editorial[data-hub-layout='hero-rama-carousel']"
      assert_selector ".street-hub-feed > .hub-hero", count: 1
      assert_selector ".hub-hero .hub-slide.is-current", count: 1
      assert_selector ".hub-hero .hub-play", count: 1
      assert_selector ".hub-hero .hub-hero-progress", count: 1
      assert_selector ".street-hub-feed > .hub-today[data-today-kind]", count: 1
      assert_selector ".hub-today__story", count: 1
      if find(".hub-today")["data-today-kind"] == "fallback"
        assert_selector ".hub-today time[data-controller='local-date']:not([hidden])", count: 1
        assert_match(/\A\d{4}-\d{2}-\d{2}\z/, find(".hub-today time")["datetime"])
      end
      assert_selector "turbo-frame#hub_watch_rail[loading='lazy']", count: 1, visible: :all
      assert_selector ".hub-explore-rail", maximum: 1
      assert_selector ".hub-expedition", maximum: 1
      assert_selector ".hub-expedition ol, .hub-expedition li", count: 0

      if expect_ward_invitation
        assert_selector ".hub-rama-presence--missing", count: 1
        assert_selector ".hub-rama-presence--missing .hub-rama-presence__action", count: 1
      end

      assert_no_selector ".hub-now, .hub-quick-actions"
      assert_no_selector ".hub-hero-league, .hub-hero-gains, .hub-reward"
      assert_no_selector ".hub-rama-card--challenge, .hub-rama-card--videos"
      assert_no_text(/\b0\s+(couronnes?|défis?|invitations?|soirées?)\b/i)

      artwork = find(".hub-hero .hub-slide-still")
      assert_equal "eager", artwork["loading"]
      assert_equal "high", artwork["fetchpriority"]
      assert_includes find(".hub-hero")["data-hub-hero-art"], "/quizzes/"
      assert_no_selector ".street-hub-feed > :not(.hub-hero) img[loading='eager'], .street-hub-feed > :not(.hub-hero) img[fetchpriority='high']"
      assert_no_selector ".quiz-hud-pack"

      order = page.evaluate_script(<<~JS)
        Array.from(document.querySelector('.street-hub-feed').children).map(function(node) {
          if (node.classList.contains('hub-hero')) return 'hero';
          if (node.classList.contains('hub-today')) return 'today';
          if (node.classList.contains('hub-expedition')) return 'expedition';
          if (node.classList.contains('hub-rama-presence')) return 'rama';
          if (node.classList.contains('hub-explore-rail')) return 'explore';
          if (node.id === 'hub_watch_rail') return 'watch';
          if (node.classList.contains('hub-identity-empty')) return 'identity';
          if (node.classList.contains('hub-install--compact')) return 'install';
          return null;
        }).filter(Boolean)
      JS
      assert_equal %w[hero today], order.first(2), order.inspect
      assert_operator order.index("watch"), :>, order.index("today"), order.inspect
      assert_operator order.index("install"), :>, order.index("watch"), order.inspect
      assert_operator order.index("rama"), :>, order.index("today"), order.inspect if order.include?("rama")
      assert_operator order.index("explore"), :>, order.index("today"), order.inspect if order.include?("explore")
    end

    def assert_home_geometry!(width:, height:, rama:)
      geometry = page.evaluate_script(<<~JS)
        (function() {
          var visible = function(node) {
            if (!node) return false;
            var style = getComputedStyle(node);
            var box = node.getBoundingClientRect();
            return !node.hidden && style.display !== 'none' && style.visibility !== 'hidden' && box.width > 0 && box.height > 0;
          };
          var actionable = Array.from(document.querySelectorAll(
            '.hub-hero .hub-play, .hub-today__story, .hub-expedition__cta, .hub-rama-presence__action, .hub-content-card, .hub-identity-empty a, .hub-install--compact a, .hub-install--compact button'
          )).filter(visible).map(function(node) {
            var box = node.getBoundingClientRect();
            return { width: box.width, height: box.height };
          });
          var missing = document.querySelector('.hub-rama-presence--missing');
          return {
            overflow: document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
            actions: actionable,
            ramaHeight: missing ? missing.getBoundingClientRect().height : null,
            dock: visible(document.querySelector('.navigation-dock')),
            nav: visible(document.querySelector('.desktop-navigation')),
            hudOutsideFeed: !document.querySelector('.street-hub-feed').contains(document.querySelector('body > .home-menu.is-hud'))
          };
        })()
      JS

      assert_not geometry.fetch("overflow"), { width:, height:, geometry: }.inspect
      assert geometry.fetch("actions").all? { |target| target.fetch("width") >= 44 && target.fetch("height") >= 44 }, geometry.inspect
      assert geometry.fetch("hudOutsideFeed"), geometry.inspect
      if rama == :missing
        assert_operator geometry.fetch("ramaHeight"), :<, 260, geometry.inspect
      else
        assert_nil geometry.fetch("ramaHeight"), geometry.inspect
      end
    end

    def assert_first_viewport_invitation!(height:)
      first_view = page.evaluate_script(<<~JS)
        (function() {
          var hero = document.querySelector('.hub-hero-stage').getBoundingClientRect();
          var play = document.querySelector('.hub-hero .hub-play').getBoundingClientRect();
          var progress = document.querySelector('.hub-hero-progress').getBoundingClientRect();
          var todayTitle = document.querySelector('.hub-today__head').getBoundingClientRect();
          var todayStory = document.querySelector('.hub-today__story').getBoundingClientRect();
          var todayEyebrow = document.querySelector('.hub-today__eyebrow').getBoundingClientRect();
          var todayHeadline = document.querySelector('.hub-today__copy > strong').getBoundingClientRect();
          return {
            heroTop: hero.top,
            playBottom: play.bottom,
            progressBottom: progress.bottom,
            todayTitleTop: todayTitle.top,
            todayTitleBottom: todayTitle.bottom,
            todayStoryTop: todayStory.top,
            todayEyebrowBottom: todayEyebrow.bottom,
            todayHeadlineTop: todayHeadline.top
          };
        })()
      JS

      assert_operator first_view.fetch("heroTop"), :>=, -1, first_view.inspect
      assert_operator first_view.fetch("heroTop"), :<=, 110, first_view.inspect
      assert_operator first_view.fetch("playBottom"), :<=, height, first_view.inspect
      assert_operator first_view.fetch("progressBottom"), :<=, height, first_view.inspect
      assert_operator first_view.fetch("todayTitleTop"), :<, height, first_view.inspect
      assert_operator first_view.fetch("todayTitleBottom"), :<=, height, first_view.inspect
      assert_operator first_view.fetch("todayStoryTop"), :<, height, first_view.inspect
      assert_operator first_view.fetch("todayEyebrowBottom"), :<=, height, first_view.inspect
      assert_operator first_view.fetch("todayHeadlineTop"), :<, height, first_view.inspect
    end

    def assert_navigation_truth!(width:, height:)
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
            dock: visible(dock) ? { position: getComputedStyle(dock).position, bottom: dock.getBoundingClientRect().bottom } : null,
            nav: visible(nav)
          };
        })()
      JS

      if width < DESKTOP_WIDTH
        assert navigation.fetch("dock"), navigation.inspect
        assert_equal "fixed", navigation.dig("dock", "position"), navigation.inspect
        assert_operator navigation.dig("dock", "bottom"), :<=, height + 1, navigation.inspect
        refute navigation.fetch("nav"), navigation.inspect
      else
        assert_nil navigation.fetch("dock"), navigation.inspect
        assert navigation.fetch("nav"), navigation.inspect
      end
    end

    def sign_in_without_ward_direct!
      name = "Noa#{SecureRandom.hex(4)}"
      session = ActionDispatch::Integration::Session.new(Rails.application)
      session.post street_profile_path, params: { name:, favorite_year: 2001, avatar_key: "gato" }
      person = Person.find_by!(given_name_key: Person.name_key(name))

      page.driver.browser.manage.delete_all_cookies
      visit root_path
      session.cookies.to_hash.each do |cookie_name, value|
        page.driver.browser.manage.add_cookie(name: cookie_name, value:, path: "/")
      end
      page.driver.browser.manage.add_cookie(name: Locale::COOKIE.to_s, value: "fr", path: "/")
      visit root_path
      person
    end

    def sign_in_ward_direct!(ward)
      session = ActionDispatch::Integration::Session.new(Rails.application)
      session.post enter_ward_path, params: { code: ward.code }

      page.driver.browser.manage.delete_all_cookies
      visit root_path
      session.cookies.to_hash.each do |name, value|
        page.driver.browser.manage.add_cookie(name:, value:, path: "/")
      end
      page.driver.browser.manage.add_cookie(name: Locale::COOKIE.to_s, value: "fr", path: "/")
      visit root_path
    end

    def shot(name)
      FileUtils.mkdir_p(SHOT_DIR)
      page.save_screenshot(SHOT_DIR.join("#{name}.png"))
    end

    def severe_browser_logs
      page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
    end
end
