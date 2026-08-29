require "application_system_test_case"

class HubCampusVisualTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/street-shots/temple-themed")

  test "the hub Campus tile turns activity into three readable animated game numbers" do
    person = people(:pili)
    seed_campus_counts!(person)
    sign_in_fixture_person_direct!(person)
    page.driver.browser.manage.add_cookie(name: Locale::COOKIE.to_s, value: "fr", path: "/")

    catalog = Array(YAML.safe_load_file(Hubs::Backdrop::CATALOG)["backdrops"])
    worlds = {
      "light" => catalog.find { |row| row.dig("theme", "mode") == "light" },
      "dark" => catalog.find { |row| row.dig("theme", "mode") == "dark" }
    }

    theme_styles = {}
    worlds.each do |theme, world|
      Hubs::Backdrop.entries = [ world ]
      [ [ 390, 844 ], [ 768, 1024 ], [ 1440, 900 ] ].each do |width, height|
        set_system_viewport(width, height)
        visit root_path
        find(".hub-duel-campus")
        page.execute_script("document.querySelector('.hub-duel-campus').scrollIntoView({ block: 'center' })")

        assert_selector "#street_world[data-hub-theme='#{theme}'] .hub-duel-campus"
        assert_selector ".hub-duel-campus[data-motion-state='ready']"
        assert_selector ".hub-duel-campus-heading", text: I18n.t("duel_campus.hub.title", locale: :fr)
        assert_selector ".hub-duel-campus-stat.is-incoming", text: "2"
        assert_selector ".hub-duel-campus-stat.is-active", text: "4"
        assert_selector ".hub-duel-campus-stat.is-results", text: "4"
        assert_no_selector ".hub-duel-campus > b"
        assert_campus_geometry!
        style = campus_theme_style
        theme_styles[theme] ||= style
        shot("hub-campus-#{theme}-#{width}x#{height}")
        assert_empty page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
      end
    end
    refute_equal theme_styles.dig("light", "headingColor"), theme_styles.dig("dark", "headingColor")
    refute_equal theme_styles.dig("light", "statBackground"), theme_styles.dig("dark", "statBackground")
    refute_equal theme_styles.dig("light", "imageFilter"), theme_styles.dig("dark", "imageFilter")

    page.driver.browser.execute_cdp(
      "Emulation.setEmulatedMedia",
      features: [ { name: "prefers-reduced-motion", value: "reduce" } ]
    )
    Hubs::Backdrop.entries = [ worlds.fetch("light") ]
    set_system_viewport(390, 844)
    visit root_path
    page.execute_script("document.querySelector('.hub-duel-campus').scrollIntoView({ block: 'center' })")
    assert_selector ".hub-duel-campus[data-motion-state='ready']"
    motion = page.evaluate_script(<<~JS)
      (function() {
        var tile = document.querySelector('.hub-duel-campus');
        var stat = tile.querySelector('.hub-duel-campus-stat');
        return {
          tileAnimation: getComputedStyle(tile).animationName,
          statAnimation: getComputedStyle(stat).animationName,
          statOpacity: getComputedStyle(stat).opacity,
          number: stat.querySelector('b').textContent.trim()
        };
      })()
    JS
    assert_equal "none", motion["tileAnimation"]
    assert_equal "none", motion["statAnimation"]
    assert_equal "1", motion["statOpacity"]
    assert_equal "2", motion["number"]
    shot("hub-campus-light-reduced-motion-390x844")
  ensure
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: []) rescue nil
    Hubs::Backdrop.reset!
  end

  private

    def seed_campus_counts!(person)
      opponents = 6.times.map do |index|
        person.ward.people.create!(
          given_name: "Campus #{index + 1}",
          avatar_key: Player::AVATARS[index % Player::AVATARS.size],
          favorite_year: 2000 + index,
          locale: "fr"
        )
      end

      opponents.last(2).each_with_index do |opponent, index|
        DuelInvitation.create!(
          challenger_person: opponent,
          recipient_person: person,
          token_digest: SecureRandom.hex(32),
          status: "open",
          source: "visual-#{index}",
          channel: "campus",
          expires_at: 7.days.from_now
        )
      end

      opponents.first(4).each_with_index do |opponent, index|
        create_duel!(
          challenger: person,
          opponent:,
          status: "active",
          suffix: "active-#{index}"
        )
      end

      opponents.first(3).each_with_index do |opponent, index|
        create_duel!(
          challenger: person,
          opponent:,
          status: "resolved",
          suffix: "resolved-#{index}",
          challenger_score: 62 + index,
          opponent_score: 54 + index
        )
      end
    end

    def create_duel!(challenger:, opponent:, status:, suffix:, challenger_score: nil, opponent_score: nil)
      invitation = DuelInvitation.create!(
        challenger_person: challenger,
        recipient_person: opponent,
        claimed_by_person: opponent,
        token_digest: SecureRandom.hex(32),
        status: "claimed",
        source: "visual-#{suffix}",
        channel: "campus",
        claimed_at: 20.minutes.ago,
        expires_at: 7.days.from_now
      )
      duel = StreetDuel.create!(
        challenger_person: challenger,
        opponent_person: opponent,
        origin_invitation: invitation,
        status:,
        accepted_at: 20.minutes.ago,
        resolved_at: (10.minutes.ago if status == "resolved"),
        challenger_score:,
        opponent_score:,
        expires_at: 7.days.from_now
      )
      invitation.update!(street_duel: duel)
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

    def assert_campus_geometry!
      geometry = page.evaluate_script(<<~JS)
        (function() {
          var tile = document.querySelector('.hub-duel-campus').getBoundingClientRect();
          var stats = Array.from(document.querySelectorAll('.hub-duel-campus-stat'));
          var numbers = Array.from(document.querySelectorAll('.hub-duel-campus-stat-value b'));
          var labels = stats.map(function(stat) { return stat.lastElementChild; });
          return {
            tileLeft: tile.left,
            tileRight: tile.right,
            viewportWidth: window.innerWidth,
            minStatWidth: Math.min.apply(Math, stats.map(function(stat) { return stat.getBoundingClientRect().width; })),
            minNumberSize: Math.min.apply(Math, numbers.map(function(number) { return parseFloat(getComputedStyle(number).fontSize); })),
            minLabelSize: Math.min.apply(Math, labels.map(function(label) { return parseFloat(getComputedStyle(label).fontSize); })),
            clipped: stats.some(function(stat) { return stat.scrollWidth > stat.clientWidth + 1 || stat.scrollHeight > stat.clientHeight + 1; }),
            hubStylesheets: Array.from(document.styleSheets).map(function(sheet) { return sheet.href; }).filter(function(href) { return href && href.indexOf('/surfaces/hub-') >= 0; })
          };
        })()
      JS
      assert_operator geometry["tileLeft"], :>=, -1
      assert_operator geometry["tileRight"], :<=, geometry["viewportWidth"] + 1
      assert_operator geometry["minStatWidth"], :>=, 84
      assert_operator geometry["minNumberSize"], :>=, 34, geometry.inspect
      assert_operator geometry["minLabelSize"], :>=, 14
      assert_equal false, geometry["clipped"]
    end

    def campus_theme_style
      page.evaluate_script(<<~JS)
        (function() {
          var tile = document.querySelector('.hub-duel-campus');
          var heading = tile.querySelector('.hub-duel-campus-heading strong');
          var stat = tile.querySelector('.hub-duel-campus-stat');
          var image = tile.querySelector('picture img');
          return {
            headingColor: getComputedStyle(heading).color,
            statBackground: getComputedStyle(stat).backgroundColor,
            imageFilter: getComputedStyle(image).filter
          };
        })()
      JS
    end

    def shot(name)
      FileUtils.mkdir_p(SHOT_DIR)
      page.save_screenshot(SHOT_DIR.join("#{name}.png"))
    end
end
