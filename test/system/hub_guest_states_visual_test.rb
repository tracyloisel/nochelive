require "application_system_test_case"

class HubGuestStatesVisualTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/street-shots/temple-mockups")
  VIEWPORTS = [ [ 320, 568 ], [ 390, 844 ], [ 768, 1024 ], [ 1024, 768 ], [ 1440, 900 ], [ 1536, 1024 ], [ 1920, 1080 ] ].freeze
  DESKTOP_WIDTH = 1200

  setup do
    page.driver.browser.manage.delete_all_cookies
    visit root_path
    page.driver.browser.manage.add_cookie(name: Locale::COOKIE.to_s, value: "fr", path: "/")
  end

  test "an anonymous visitor sees an honest compact Hub in both celestial themes" do
    theme_worlds.each do |theme, world|
      Hubs::Backdrop.entries = [ world ]

      VIEWPORTS.each do |width, height|
        set_system_viewport(width, height)
        visit root_path

        assert_selector "#street_world[data-hub-theme='#{theme}']"
        assert_pack_artwork!
        assert_guest_truth!(width:, height:)
        shot("hub-guest-editorial-#{theme}-#{width}x#{height}") if [ 390, 768, 1440 ].include?(width)
        assert_empty severe_browser_logs, "Guest Hub console errors at #{theme} #{width}x#{height}: #{severe_browser_logs.inspect}"
      end
    end
  ensure
    Hubs::Backdrop.reset!
  end

  test "a ward-only session keeps public actions visible and asks for the first linked player" do
    sign_in_ward_direct!(wards(:blank))

    theme_worlds.each do |theme, world|
      Hubs::Backdrop.entries = [ world ]

      [ [ 390, 844 ], [ 1440, 900 ] ].each do |width, height|
        set_system_viewport(width, height)
        visit root_path

        assert_selector "#street_world[data-hub-theme='#{theme}']"
        assert_pack_artwork!
        assert_ward_without_player_truth!(width:, height:)
        assert_empty severe_browser_logs, "Ward-only Hub console errors at #{theme} #{width}x#{height}: #{severe_browser_logs.inspect}"
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

    def assert_pack_artwork!
      hero = find(".hub-hero[data-hub-hero-art]")
      assert_includes hero["data-hub-hero-art"], "/quizzes/"
      refute_includes hero["data-hub-hero-art"], "salt-lake-temple"
      assert_selector ".hub-hero .hub-slide-still"
    end

    def assert_guest_truth!(width:, height:)
      snapshot = hub_state_snapshot

      assert snapshot.fetch("editorial"), snapshot.inspect
      assert_equal "hero-rama-carousel", snapshot.fetch("layout"), snapshot.inspect
      assert snapshot.fetch("hero"), snapshot.inspect
      assert_equal 1, snapshot.fetch("heroPlay"), snapshot.inspect
      assert snapshot.fetch("live"), snapshot.inspect
      assert snapshot.fetch("wardMissing"), snapshot.inspect
      assert_equal street_profile_path(quick: 1, fresh: 1, ward_next: 1), snapshot.fetch("wardPath"), snapshot.inspect
      assert_operator snapshot.fetch("publicRailCards"), :>=, 1, snapshot.inspect
      assert_equal 0, snapshot.fetch("personal"), snapshot.inspect
      assert_equal 0, snapshot.fetch("identityEmpty"), snapshot.inspect
      assert snapshot.fetch("utilitiesInCarousel"), snapshot.inspect
      assert_public_actions_visible!(snapshot)
      assert_not snapshot.fetch("overflow"), snapshot.inspect
      assert snapshot.fetch("guestHud"), snapshot.inspect
      assert_equal 0, snapshot.fetch("guestHudCta"), snapshot.inspect

      assert_navigation_truth!(snapshot, width:, height:)
    end

    def assert_ward_without_player_truth!(width:, height:)
      snapshot = hub_state_snapshot

      assert snapshot.fetch("editorial"), snapshot.inspect
      assert_equal "hero-rama-carousel", snapshot.fetch("layout"), snapshot.inspect
      assert snapshot.fetch("live"), snapshot.inspect
      assert_not snapshot.fetch("wardMissing"), snapshot.inspect
      assert snapshot.fetch("liveEmpty"), snapshot.inspect
      assert_operator snapshot.fetch("publicRailCards"), :>=, 3, snapshot.inspect
      assert_equal 0, snapshot.fetch("personal"), snapshot.inspect
      assert_equal 1, snapshot.fetch("identityEmpty"), snapshot.inspect
      assert_equal 1, snapshot.fetch("playerMissing"), snapshot.inspect
      assert_equal 0, snapshot.fetch("playerUnselected"), snapshot.inspect
      assert snapshot.fetch("identityAfterInstall"), snapshot.inspect
      assert snapshot.fetch("utilitiesInCarousel"), snapshot.inspect
      assert_public_actions_visible!(snapshot)
      assert_not snapshot.fetch("overflow"), snapshot.inspect
      assert snapshot.fetch("guestHud"), snapshot.inspect
      assert_equal 0, snapshot.fetch("guestHudCta"), snapshot.inspect

      assert_navigation_truth!(snapshot, width:, height:)
    end

    def hub_state_snapshot
      page.evaluate_script(<<~JS)
        (function() {
          var feed = document.querySelector('.street-hub-feed');
          var visible = function(element) {
            if (!element) return false;
            var style = getComputedStyle(element);
            var rect = element.getBoundingClientRect();
            return !element.hidden && style.display !== 'none' && style.visibility !== 'hidden' && rect.width >= 44 && rect.height >= 44;
          };
          var hero = feed && Array.from(feed.children).find(function(node) { return node.classList.contains('hub-hero'); });
          var live = feed && feed.querySelector(':scope > .hub-rama-carousel .hub-live--feature');
          var challenges = feed && feed.querySelector(':scope > .hub-rama-carousel .hub-rama-card--challenge');
          var videos = feed && feed.querySelector(':scope > .hub-rama-carousel .hub-rama-card--videos');
          var dock = document.querySelector('.navigation-dock');
          var nav = document.querySelector('.desktop-navigation');
          return {
            editorial: feed && feed.classList.contains('hub-streaming-feed--editorial'),
            layout: feed && feed.dataset.hubLayout,
            hero: Boolean(hero),
            heroPlay: hero && hero.querySelectorAll('.hub-play').length,
            live: Boolean(live),
            wardMissing: Boolean(live && live.classList.contains('is-ward_missing')),
            liveEmpty: Boolean(live && live.classList.contains('is-empty')),
            wardPath: live && live.querySelector('.hub-live-program')?.getAttribute('href'),
            publicRailCards: feed ? feed.querySelectorAll(':scope > .hub-rama-carousel .hub-rama-card').length : -1,
            personal: feed ? feed.querySelectorAll(':scope > .hub-now').length : -1,
            identityEmpty: feed ? feed.querySelectorAll(':scope > .hub-identity-empty').length : -1,
            playerMissing: feed ? feed.querySelectorAll(':scope > .hub-identity-empty.is-player-missing').length : -1,
            playerUnselected: feed ? feed.querySelectorAll(':scope > .hub-identity-empty.is-player-unselected').length : -1,
            challengesPath: challenges && challenges.getAttribute('href'),
            challengesVisible: visible(challenges),
            videosPath: videos && videos.getAttribute('href'),
            videosVisible: visible(videos),
            utilitiesInCarousel: Boolean(challenges && videos),
            identityAfterInstall: Boolean(feed && feed.querySelector(':scope > .hub-install + .hub-identity-empty')),
            overflow: document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
            dock: dock && visible(dock) ? { position: getComputedStyle(dock).position, bottom: dock.getBoundingClientRect().bottom } : null,
            nav: Boolean(nav && visible(nav)),
            guestHud: Boolean(document.querySelector('.quiz-hud.is-guest .quiz-hud-who.is-guest')),
            guestHudCta: document.querySelectorAll('.quiz-hud.is-guest .quiz-hud-cta').length
          };
        })()
      JS
    end

    def assert_public_actions_visible!(snapshot)
      assert_equal street_challenges_path, snapshot.fetch("challengesPath"), snapshot.inspect
      assert snapshot.fetch("challengesVisible"), snapshot.inspect
      assert_equal church_videos_path(locale: :fr), snapshot.fetch("videosPath"), snapshot.inspect
      assert snapshot.fetch("videosVisible"), snapshot.inspect
    end

    def assert_navigation_truth!(snapshot, width:, height:)
      if width < DESKTOP_WIDTH
        assert snapshot.fetch("dock"), snapshot.inspect
        assert_equal "fixed", snapshot.dig("dock", "position"), snapshot.inspect
        assert_operator snapshot.dig("dock", "bottom"), :<=, height + 1, snapshot.inspect
        refute snapshot.fetch("nav"), snapshot.inspect
      else
        assert_nil snapshot.fetch("dock"), snapshot.inspect
        assert snapshot.fetch("nav"), snapshot.inspect
      end
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
