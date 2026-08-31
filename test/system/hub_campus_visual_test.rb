require "application_system_test_case"

class HubCampusVisualTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/street-shots/temple-themed")

  test "one real incoming challenge becomes the top Now action instead of a Hub rail" do
    person = people(:pili)
    seed_campus_actions!(person)
    sign_in_fixture_person_direct!(person)
    page.driver.browser.manage.add_cookie(name: Locale::COOKIE.to_s, value: "fr", path: "/")

    theme_worlds.each do |theme, world|
      Hubs::Backdrop.entries = [ world ]
      [ [ 390, 844 ], [ 768, 1024 ], [ 1440, 900 ] ].each do |width, height|
        set_system_viewport(width, height)
        visit root_path

        snapshot = page.evaluate_script(<<~JS)
          (function() {
            var now = document.querySelector('.hub-now');
            var cards = Array.from(now ? now.querySelectorAll('.hub-now-card') : []);
            var first = cards[0];
            var rect = first && first.getBoundingClientRect();
            return {
              now: Boolean(now),
              cards: cards.length,
              incoming: now ? now.querySelectorAll('.hub-now-card--challenge.is-incoming').length : -1,
              active: now ? now.querySelectorAll('.hub-now-card--challenge.is-your_turn, .hub-now-card--challenge.is-ready').length : -1,
              formAction: first && first.closest('form')?.getAttribute('action'),
              formMethod: first && first.closest('form')?.getAttribute('method'),
              overflow: document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
              card: rect && { width: rect.width, height: rect.height }
            };
          })()
        JS

        assert_selector "#street_world[data-hub-theme='#{theme}']"
        assert snapshot.fetch("now"), snapshot.inspect
        assert_equal 1, snapshot.fetch("incoming"), snapshot.inspect
        assert_equal 0, snapshot.fetch("active"), snapshot.inspect
        assert_operator snapshot.fetch("cards"), :<=, 2, snapshot.inspect
        assert_match(%r{\A/desafio/.+\z}, snapshot.fetch("formAction"), snapshot.inspect)
        assert_equal "post", snapshot.fetch("formMethod"), snapshot.inspect
        assert_not snapshot.fetch("overflow"), snapshot.inspect
        assert_operator snapshot.dig("card", "width"), :>=, 44, snapshot.inspect
        assert_operator snapshot.dig("card", "height"), :>=, 44, snapshot.inspect
        assert_empty severe_browser_logs

        page.execute_script("document.querySelector('.hub-now').scrollIntoView({ block: 'center', behavior: 'auto' })")
        FileUtils.mkdir_p(SHOT_DIR)
        page.save_screenshot(SHOT_DIR.join("hub-now-challenge-#{theme}-#{width}x#{height}.png"))
      end
    end
  ensure
    Hubs::Backdrop.reset!
  end

  private

    def theme_worlds
      catalog = Array(YAML.safe_load_file(Hubs::Backdrop::CATALOG)["backdrops"])
      {
        "light" => catalog.find { |row| row["id"] == "royal-jerusalem-dawn" },
        "dark" => catalog.find { |row| row["id"] == "coronas-ungido" }
      }.tap { |worlds| assert worlds.values.all? }
    end

    def seed_campus_actions!(person)
      early = person.ward.people.create!(
        given_name: "Ada",
        avatar_key: Player::AVATARS.first,
        favorite_year: 2001,
        locale: "fr"
      )
      late = person.ward.people.create!(
        given_name: "Noé",
        avatar_key: Player::AVATARS.second,
        favorite_year: 2002,
        locale: "fr"
      )
      invitation = DuelInvitation.create!(
        challenger_person: early,
        recipient_person: person,
        token_digest: SecureRandom.hex(32),
        status: "open",
        source: "hub-now-early",
        channel: "campus",
        expires_at: 1.day.from_now
      )
      DuelInvitation.create!(
        challenger_person: late,
        recipient_person: person,
        token_digest: SecureRandom.hex(32),
        status: "open",
        source: "hub-now-late",
        channel: "campus",
        expires_at: 2.days.from_now
      )
      invitation
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

    def severe_browser_logs
      page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
    end
end
