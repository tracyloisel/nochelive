require "application_system_test_case"

class ScriptureReaderCircleVisualTest < ApplicationSystemTestCase
  VIEWPORTS = [ [ 390, 844 ], [ 768, 1024 ], [ 1440, 900 ] ].freeze

  setup do
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @viewer = people(:pili)
    @author = people(:carmen_garcia)
    @other_member = people(:carmen_lopez)
    @root = publish_circle_post(
      person: @author,
      kind: "question",
      body: "Comment garder confiance quand une parole reçue continue de tourner dans mon cœur ?"
    )
    publish_circle_post(
      person: @author,
      kind: "reply",
      parent_id: @root.id,
      body: "Je commence par nommer ce qui me blesse, puis je relis le passage lentement."
    )
    5.times do |index|
      publish_circle_post(
        person: @other_member,
        kind: "reply",
        parent_id: @root.id,
        body: "Réponse récente #{index + 1} : je garde une phrase avec moi pendant la journée."
      )
    end

    sign_in_fixture_person_direct!(@viewer)
    page.driver.browser.manage.add_cookie(name: Locale::COOKIE.to_s, value: "fr", path: "/")
    page.execute_script("window.localStorage.clear()")
    page.driver.browser.logs.get(:browser) # Ignore the Hub page used only to install the fixture session.
    FileUtils.mkdir_p(screenshot_directory) if capture_screenshots?
  end

  teardown do
    Scriptures::Read.fetcher = nil
  end

  test "the reader Circle keeps a quiet conversational hierarchy at every production viewport" do
    VIEWPORTS.each do |width, height|
      set_system_viewport(width, height)
      visit scripture_path("ot/ps/52", locale: "fr", circle: 1)
      scroll_circle_into_view(find("#reader-circle", visible: :all))
      wait_for_paint!

      conversation = find("[data-circle-conversation-root-id='#{@root.id}']", visible: :all)
      assert_selector ".reader-circle-compose-form textarea", visible: true
      assert_selector ".reader-circle-compose-form input[type='hidden'][name='post[kind]'][value='question']", visible: :all
      audience_picker = find("details.reader-circle-audience[data-circle-author-visibility]")
      audience_summary = audience_picker.find("summary")
      assert_equal "Publier avec mon nom", audience_summary.text
      audience_summary.click
      assert_selector "details.reader-circle-audience[open] [role='listbox']", visible: true
      if width == 390
        audience_summary.send_keys(:escape)
        assert_no_selector "details.reader-circle-audience[open]"
        assert_selector ".scripture-reader-room[role='dialog']", visible: true
        audience_summary.click
      end
      audience_picker.find("[data-author-visibility-value='anonymous_to_ward']").click
      assert_no_selector "details.reader-circle-audience[open]"
      assert_equal "Publier anonymement", audience_summary.text
      assert_equal "anonymous_to_ward", audience_picker.find("[data-circle-author-visibility-input]", visible: :all).value
      audience_summary.click
      page.execute_script("document.querySelector('.reader-circle-compose-form textarea').click()")
      assert_no_selector "details.reader-circle-audience[open]"
      audience_summary.click
      audience_picker.find("[data-author-visibility-value='named']").click
      assert_equal "Publier avec mon nom", audience_summary.text
      assert_equal "named", audience_picker.find("[data-circle-author-visibility-input]", visible: :all).value
      assert_no_selector ".reader-circle-kind-options"
      assert_no_selector ".reader-circle-rail"
      assert_selector ".reader-circle-tab.is-active", text: "Récentes"
      assert_selector ".reader-circle-tab", text: "Sans réponse"
      assert_selector "[data-circle-conversation-root-id='#{@root.id}'] .reader-circle-latest-replies > .reader-circle-message.is-reply", count: 5
      assert_selector "[data-circle-conversation-root-id='#{@root.id}'] button.reader-circle-history-toggle", visible: true
      assert_selector "[data-circle-conversation-root-id='#{@root.id}'] .reader-circle-reply-composer textarea", visible: true
      assert_selector "[data-circle-conversation-root-id='#{@root.id}'] .circle-post-vote-form", minimum: 1
      assert_reddit_reader_geometry!(conversation, width)
      if width == 390
        composer_position = page.evaluate_script("getComputedStyle(document.querySelector('[data-circle-conversation-root-id=\"#{@root.id}\"] [data-circle-reply-composer]')).position")
        assert_equal "fixed", composer_position
      end
      assert_empty severe_browser_logs

      if capture_screenshots?
        scroll_circle_into_view(conversation)
        wait_for_paint!
        save_screenshot screenshot_directory.join("circle-reader-#{width}x#{height}.png")
      end

      next unless width == 390

      history_toggle = find("[data-circle-conversation-root-id='#{@root.id}'] .reader-circle-history-toggle")
      history_toggle.click
      assert_equal "true", history_toggle["aria-expanded"]
      assert_selector "[data-circle-conversation-root-id='#{@root.id}'] .reader-circle-history-messages:not([hidden]) .reader-circle-message", count: 1

      reply = first("[data-circle-conversation-root-id='#{@root.id}'] .reader-circle-latest-replies .reader-circle-message.is-reply")
      reply.click
      composer = find("[data-circle-conversation-root-id='#{@root.id}'] [data-circle-reply-composer]")
      assert_selector "[data-circle-reply-heading]", text: /Répondre à/
      assert_equal reply["data-circle-post-id"], composer.find("[data-circle-reply-parent]", visible: :all).value

      within composer do
        find(".circle-reply-verse-trigger").click
        fill_in "reader-feed-reply-verse-input-#{@root.id}", with: "2, 4-5"
        click_button "Joindre"
        assert_selector "[data-circle-reply-verse-label]", text: "Psaume 52:2, 4–5"
        assert_equal "2, 4-5", find("input[name='post[selected_verses]']", visible: :all).value
      end
      page.execute_script("window.localStorage.clear()")
    end
  end

  test "the reader toolbar toggles marks and Circle back to the reading position" do
    [ [ 390, 844 ], [ 1440, 900 ] ].each do |width, height|
      set_system_viewport(width, height)
      visit scripture_path("ot/ps/52", locale: "fr")

      if width == 390
        page.execute_script("document.querySelector('[data-preference-key=\"font_scale\"][value=\"100\"]').click()")
        regular_toolbar_size = page.evaluate_script("parseFloat(getComputedStyle(document.querySelector('.scripture-selection-bar button')).fontSize)")
        page.execute_script("document.querySelector('[data-preference-key=\"font_scale\"][value=\"115\"]').click()")
        enlarged_toolbar_size = page.evaluate_script("parseFloat(getComputedStyle(document.querySelector('.scripture-selection-bar button')).fontSize)")
        assert_in_delta regular_toolbar_size * 1.15, enlarged_toolbar_size, 0.2
        page.execute_script("document.querySelector('[data-preference-key=\"font_scale\"][value=\"100\"]').click()")
      end

      marks_trigger = find("[data-scripture-room-target='marksTrigger']")
      assert_equal "false", marks_trigger["aria-expanded"]
      marks_trigger.click
      assert_selector "[data-scripture-room-target='marksTrigger'][aria-expanded='true'][aria-label='Retour au chapitre']"
      assert_selector "#reader-companion:not([hidden])", visible: true
      assert_no_selector ".reader-marks-panel .reader-return-to-reading"

      close_trigger = find("[data-scripture-room-target='closeTrigger']")
      if width == 390
        assert_equal "Retour au chapitre", close_trigger["aria-label"]
        close_trigger.click
        assert_selector ".scripture-reader-room[role='dialog']", visible: true
        assert_selector "[data-scripture-room-target='closeTrigger'][aria-label='Fermer la liseuse']"
      else
        assert_equal "Fermer la liseuse", close_trigger["aria-label"]
        marks_trigger.click
      end
      assert_selector "[data-scripture-room-target='marksTrigger'][aria-expanded='false'][aria-label='Ouvrir mes repères']"
      assert_selector "#reader-companion[hidden]", visible: :all

      sheet_scroll_top = page.evaluate_script("document.querySelector('.scripture-sheet').scrollTop")
      circle_trigger = find("[data-scripture-room-target='circleTrigger']")
      circle_trigger.click
      assert_selector "[data-scripture-room-target='circleTrigger'][aria-expanded='true'][aria-label='Retour au chapitre']"
      wait_for_reader_scroll!
      assert_operator page.evaluate_script("document.querySelector('.scripture-sheet').scrollTop"), :>, sheet_scroll_top

      circle_trigger.click
      assert_selector "[data-scripture-room-target='circleTrigger'][aria-expanded='false'][aria-label='Aller au Forum']"
      wait_for_reader_scroll!(target: sheet_scroll_top)
      returned_scroll_top = page.evaluate_script("document.querySelector('.scripture-sheet').scrollTop")
      assert_in_delta sheet_scroll_top, returned_scroll_top, 2
      assert_empty severe_browser_logs
    end
  end

  test "publishing preserves the reading sheet position and applies the reading text scale to my message" do
    set_system_viewport(390, 844)
    visit scripture_path("ot/ps/52", locale: "fr", circle: 1)
    scroll_circle_into_view(find("#reader-circle", visible: :all))

    body = "Je garde cette parole avec moi sans perdre ma place dans le chapitre."
    fill_in "circle-post-body", with: body
    before_scroll = page.evaluate_script("document.querySelector('.scripture-sheet').scrollTop")
    assert_operator before_scroll, :>, 100

    find(".reader-circle-compose-form .reader-circle-submit").click
    assert_selector ".reader-circle-message.is-own .circle-message-body", text: body
    wait_for_reader_scroll!(target: before_scroll)

    after_scroll = page.evaluate_script("document.querySelector('.scripture-sheet').scrollTop")
    assert_in_delta before_scroll, after_scroll, 3

    own_message = find(".reader-circle-message.is-own .circle-message-body", text: body)
    regular_size = page.evaluate_script("parseFloat(getComputedStyle(arguments[0]).fontSize)", own_message)
    assert_equal 400, page.evaluate_script("parseInt(getComputedStyle(arguments[0]).fontWeight, 10)", own_message)

    page.execute_script("document.querySelector('[data-preference-key=\"font_scale\"][value=\"115\"]').click()")
    enlarged_size = page.evaluate_script("parseFloat(getComputedStyle(arguments[0]).fontSize)", own_message)
    assert_in_delta regular_size * 1.15, enlarged_size, 0.2
    assert_empty severe_browser_logs
  end

  private

    def publish_circle_post(person:, kind:, body:, parent_id: nil)
      ScriptureCircles::Publish.call(
        person:,
        reference: "ot/ps/52",
        attributes: { kind:, locale: "fr", body:, parent_id: }.compact
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

    def assert_reddit_reader_geometry!(conversation, expected_width)
      geometry = page.evaluate_script(<<~JS)
        (function() {
          var circle = document.querySelector('#reader-circle');
          var root = document.querySelector("[data-circle-conversation-root-id='#{@root.id}']");
          var headline = root.querySelector('.reader-circle-message.is-root .circle-message-body');
          var author = root.querySelector('.reader-circle-message.is-root .reader-circle-message-author strong');
          var visibleControls = Array.from(circle.querySelectorAll('button, a, select, summary')).filter(function(control) {
            var style = window.getComputedStyle(control);
            var rect = control.getBoundingClientRect();
            return style.display !== 'none' && style.visibility !== 'hidden' && rect.width > 0 && rect.height > 0;
          });
          return {
            viewportWidth: window.innerWidth,
            documentWidth: document.documentElement.scrollWidth,
            circleRight: circle.getBoundingClientRect().right,
            headlineSize: parseFloat(window.getComputedStyle(headline).fontSize),
            authorSize: parseFloat(window.getComputedStyle(author).fontSize),
            undersizedControls: visibleControls.filter(function(control) {
              var rect = control.getBoundingClientRect();
              return rect.height < 43.5;
            }).map(function(control) { return control.className || control.tagName; })
          };
        })()
      JS

      assert_equal expected_width, geometry.fetch("viewportWidth")
      assert_operator geometry.fetch("documentWidth"), :<=, expected_width + 1, geometry.inspect
      assert_operator geometry.fetch("circleRight"), :<=, expected_width + 1, geometry.inspect
      assert_operator geometry.fetch("headlineSize"), :>, geometry.fetch("authorSize"), geometry.inspect
      assert_empty geometry.fetch("undersizedControls"), geometry.inspect
      assert conversation.visible?
    end

    def wait_for_paint!
      page.driver.browser.execute_async_script(<<~JS)
        var done = arguments[0];
        var finish = function() { window.setTimeout(function() { done(true); }, 80); };
        if (document.fonts && document.fonts.ready) document.fonts.ready.then(finish);
        else finish();
      JS
    end

    def wait_for_reader_scroll!(target: nil)
      page.driver.browser.execute_async_script(<<~JS, target)
        var target = arguments[0];
        var done = arguments[1];
        var startedAt = Date.now();
        var check = function() {
          var current = document.querySelector('.scripture-sheet').scrollTop;
          if (target === null || Math.abs(current - target) <= 2 || Date.now() - startedAt > 2500) done(true);
          else window.requestAnimationFrame(check);
        };
        window.setTimeout(check, target === null ? 550 : 0);
      JS
    end

    def scroll_circle_into_view(element)
      page.execute_script(<<~JS, element)
        arguments[0].scrollIntoView({ block: 'start', behavior: 'instant' });
        var sheet = arguments[0].closest('.scripture-sheet');
        if (sheet) sheet.scrollTop = Math.max(0, sheet.scrollTop - 76);
      JS
    end

    def severe_browser_logs
      page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
    end

    def capture_screenshots?
      ENV["CIRCLE_SCREENSHOTS"] == "1"
    end

    def screenshot_directory
      Rails.root.join("tmp", "circle-reader-shots")
    end
end
