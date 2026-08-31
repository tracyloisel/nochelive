require "application_system_test_case"

class ScriptureCircleVisualTest < ApplicationSystemTestCase
  setup do
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @viewer = people(:pili)
    @author = people(:carmen_garcia)
    @other_member = people(:carmen_lopez)
    @question = publish_circle_post(
      person: @author,
      reference: "ot/ps/52",
      kind: "question",
      body: "Comment relire ce passage avec douceur quand une parole nous blesse ?"
    )
    @reflection = publish_circle_post(
      person: @author,
      reference: "bofm/alma/32",
      kind: "reflection",
      body: "Cette image de la semence me donne envie de prendre le temps de méditer."
    )
    publish_circle_post(
      person: @other_member,
      reference: @reflection.scripture_circle_thread.reference,
      kind: "reply",
      parent_id: @reflection.id,
      body: "Je commence par relire une phrase à la fois, sans me presser."
    )

    sign_in_fixture_person_direct!(@viewer)
    page.driver.browser.manage.add_cookie(name: Locale::COOKIE.to_s, value: "fr", path: "/")
  end

  test "desktop opens the first helpful conversation beside the compact chapter inbox" do
    set_system_viewport(1440, 900)
    visit scripture_circle_path(locale: "fr")
    wait_for_circle_paint!

    assert_selector "body.is-scripture-circle-index.is-celestial-light"
    assert_selector "section#circle_index.circle-page[data-controller~='circle-feed']"
    assert_selector "header.quiz-hud"
    assert_selector "nav.navigation-dock"
    assert_selector "turbo-frame#circle_live_feed"
    assert_selector ".circle-workspace"
    assert_selector ".circle-inbox", visible: true
    assert_selector ".circle-thread", visible: true
    assert_selector ".circle-inbox-tab.is-active[aria-current='page']", text: I18n.t("scripture_circle.filters.all", locale: :fr)
    assert_selector ".circle-inbox-row-link", minimum: 1
    assert_selector ".circle-inbox-row.is-selected .circle-inbox-sender", text: "Psaumes 52"
    assert_selector ".circle-thread-heading h2", text: "Psaumes 52"
    assert_selector ".circle-thread-compose-form[data-turbo-frame='circle_live_feed'] textarea", visible: true
    assert_selector ".circle-thread-send", visible: true
    assert_selector "a.circle-reader-link[data-turbo-frame='scripture_reader']", text: I18n.t("scripture_circle.inbox.reread", locale: :fr)

    # Selecting an exchange stays in the Circle. The chapter link is the only
    # intentional route into the reader, and the global chrome is reused.
    assert_no_selector "a.circle-inbox-row-link[data-turbo-frame='scripture_reader']"
    assert_no_selector ".circle-desktop-rail, .circle-overview-card, .circle-card-link, .circle-reading-card, #circle_results"
    assert_compact_desktop_circle_layout!
    assert_no_horizontal_circle_overflow!
    assert_empty severe_browser_logs
  end

  test "mobile starts in the inbox and opens a thread only after its row is tapped" do
    set_system_viewport(390, 844)
    visit scripture_circle_path(locale: "fr")
    wait_for_circle_paint!

    assert_selector "header.quiz-hud", visible: true
    assert_selector "nav.navigation-dock", visible: true
    assert_selector ".circle-workspace:not(.is-thread-open)"
    assert_selector ".circle-inbox", visible: true
    assert_no_selector ".circle-thread", visible: true
    assert_selector ".circle-inbox-row-link", text: @question.body

    find(".circle-inbox-row-link", text: @question.body).click

    assert_selector ".circle-workspace.is-thread-open"
    assert_no_selector ".circle-inbox", visible: true
    assert_selector ".circle-thread", visible: true
    assert_selector ".circle-thread-heading h2", text: "Psaumes 52"
    assert_selector "textarea#circle-reply-#{@question.id}", visible: true
    assert_selector "a.circle-thread-back", visible: true
    assert_no_horizontal_circle_overflow!

    find("a.circle-thread-back").click

    assert_selector ".circle-workspace:not(.is-thread-open)"
    assert_selector ".circle-inbox", visible: true
    assert_no_selector ".circle-thread", visible: true
    assert_empty severe_browser_logs
  end

  private

    def publish_circle_post(person:, reference:, kind:, body:, parent_id: nil)
      ScriptureCircles::Publish.call(
        person:,
        reference:,
        attributes: {
          kind:,
          locale: "fr",
          body:,
          parent_id:
        }.compact
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
    end

    def wait_for_circle_paint!
      painted = page.driver.browser.execute_async_script(<<~JS)
        var done = arguments[0];
        var finish = function() { window.setTimeout(function() { done(true); }, 70); };
        var fallback = new Promise(function(resolve) { window.setTimeout(resolve, 2500); });
        if (document.fonts && document.fonts.ready) {
          Promise.race([document.fonts.ready, fallback]).then(finish);
        } else {
          finish();
        }
      JS
      assert painted, "Circle assertions must wait until web fonts have had a chance to paint"
    end

    def assert_no_horizontal_circle_overflow!
      geometry = page.evaluate_script(<<~JS)
        (function() {
          return {
            viewportWidth: window.innerWidth,
            documentWidth: document.documentElement.scrollWidth,
            copyOverflows: Array.from(document.querySelectorAll('.circle-hero-lede, .circle-inbox-subject, .circle-inbox-activity, .circle-thread-heading h2, .circle-thread-heading p, .circle-thread-message-copy p')).filter(function(element) {
              return element.scrollWidth > element.clientWidth + 3;
            }).map(function(element) { return element.textContent.trim(); })
          };
        })()
      JS

      assert_operator geometry.fetch("documentWidth"), :<=, geometry.fetch("viewportWidth") + 1, geometry.inspect
      assert_empty geometry.fetch("copyOverflows"), geometry.inspect
    end

    def assert_compact_desktop_circle_layout!
      geometry = page.evaluate_script(<<~JS)
        (function() {
          var rows = Array.from(document.querySelectorAll('.circle-inbox-row')).map(function(row) {
            return row.getBoundingClientRect();
          });
          var thread = document.querySelector('.circle-thread').getBoundingClientRect();
          return {
            viewportHeight: window.innerHeight,
            threadHeight: thread.height,
            rowGaps: rows.slice(1).map(function(row, index) { return row.top - rows[index].bottom; })
          };
        })()
      JS

      assert_operator geometry.fetch("threadHeight"), :<, geometry.fetch("viewportHeight") * 0.65, geometry.inspect
      assert geometry.fetch("rowGaps").all? { |gap| gap <= 2 }, geometry.inspect
    end

    def severe_browser_logs
      page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
    end
end
