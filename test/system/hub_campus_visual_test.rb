require "application_system_test_case"

class HubCampusVisualTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/street-shots/temple-themed")

  test "one real incoming challenge becomes a focused Rama presence" do
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
            var rama = document.querySelector('.hub-rama-presence');
            var cards = Array.from(rama ? rama.querySelectorAll('.hub-rama-event') : []);
            var challenge = rama && rama.querySelector('.hub-rama-event--challenge');
            var rect = challenge && challenge.getBoundingClientRect();
            return {
              rama: Boolean(rama),
              cards: cards.length,
              challenge: rama ? rama.querySelectorAll('.hub-rama-event--challenge').length : -1,
              challengeIndex: cards.indexOf(challenge),
              formAction: challenge && challenge.closest('form')?.getAttribute('action'),
              formMethod: challenge && challenge.closest('form')?.getAttribute('method'),
              overflow: document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
              card: rect && { width: rect.width, height: rect.height }
            };
          })()
        JS

        assert_selector "#street_world[data-hub-theme='#{theme}']"
        assert snapshot.fetch("rama"), snapshot.inspect
        assert_equal 1, snapshot.fetch("challenge"), snapshot.inspect
        assert_equal 0, snapshot.fetch("challengeIndex"), snapshot.inspect
        assert_operator snapshot.fetch("cards"), :<=, 3, snapshot.inspect
        assert_match(%r{\A/desafio/.+\z}, snapshot.fetch("formAction"), snapshot.inspect)
        assert_equal "post", snapshot.fetch("formMethod"), snapshot.inspect
        assert_selector ".hub-rama-event--challenge .hub-rama-event__kicker",
          text: /#{Regexp.escape(I18n.t("hub.now.challenge_incoming", name: "Ada", locale: :fr))}/i
        assert_selector ".hub-rama-event--challenge strong",
          text: I18n.with_locale(:fr) { QuizDefinition.catalog.find_pack("coronas").copy(:title) }
        assert_selector ".hub-rama-event--challenge .hub-rama-event__action",
          text: /#{Regexp.escape(I18n.t("hub.now.challenge_accept", locale: :fr))}/i
        assert_not snapshot.fetch("overflow"), snapshot.inspect
        assert_operator snapshot.dig("card", "width"), :>=, 44, snapshot.inspect
        assert_operator snapshot.dig("card", "height"), :>=, 44, snapshot.inspect
        assert_empty severe_browser_logs

        page.execute_script("document.querySelector('.hub-rama-presence').scrollIntoView({ block: 'center', behavior: 'auto' })")
        FileUtils.mkdir_p(SHOT_DIR)
        page.save_screenshot(SHOT_DIR.join("hub-rama-challenge-#{theme}-#{width}x#{height}.png"))
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
        challenger_run: QuizRun.create!(
          person: early,
          device_digest: "hub-rama-early-#{SecureRandom.hex(8)}",
          pack_id: "coronas",
          position: 10,
          score: 89,
          status: "finished",
          opened_at: 1.hour.ago
        ),
        challenger_score: 89,
        token_digest: SecureRandom.hex(32),
        status: "open",
        source: "hub-rama-early",
        channel: "campus",
        expires_at: 1.day.from_now
      )
      DuelInvitation.create!(
        challenger_person: late,
        recipient_person: person,
        token_digest: SecureRandom.hex(32),
        status: "open",
        source: "hub-rama-late",
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
