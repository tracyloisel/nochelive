require "application_system_test_case"

class ScriptureCircleRealtimeTest < ApplicationSystemTestCase
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
      body: "Quelle parole puis-je offrir à quelqu’un qui doute aujourd’hui ?"
    )
    @reflection = publish_circle_post(
      person: @author,
      reference: "bofm/alma/32",
      kind: "reflection",
      body: "Cette image de la semence me donne envie de prendre le temps de méditer."
    )

    sign_in_fixture_person_direct!(@viewer)
    page.driver.browser.manage.add_cookie(name: Locale::COOKIE.to_s, value: "fr", path: "/")
  end

  test "defers a WebSocket refresh for a dirty draft and preserves it after explicit refresh" do
    visit_selected_reflection
    install_circle_realtime_signals!

    draft = "Je garde cette réponse en cours, même si une nouvelle parole arrive."
    field = find(".circle-thread-compose-form textarea")
    field.set(draft)
    page.execute_script("arguments[0].blur()", field)

    external_reply = publish_circle_post(
      person: @other_member,
      reference: @reflection.scripture_circle_thread.reference,
      kind: "reply",
      parent_id: @reflection.id,
      body: "Je relis ce chapitre à voix haute quand j’ai besoin de reprendre courage."
    )

    assert wait_for_circle_realtime_signal("refreshes"), page.evaluate_script("window.circleRealtimeSignals")
    assert wait_without_circle_frame_load, page.evaluate_script("window.circleRealtimeSignals")
    assert_selector ".circle-refresh-action", text: I18n.t("scripture_circle.inbox.refresh", locale: :fr), visible: true
    assert_selector ".circle-refresh-notice", text: I18n.t("scripture_circle.inbox.pending_refresh", locale: :fr), visible: true
    assert_equal draft, find(".circle-thread-compose-form textarea").value
    assert_no_selector ".circle-thread-message", text: external_reply.body

    find(".circle-refresh-action").click

    assert wait_for_circle_realtime_signal("loads"), page.evaluate_script("window.circleRealtimeSignals")
    assert_selector ".circle-thread-message", text: external_reply.body
    assert_equal draft, find(".circle-thread-compose-form textarea").value
    assert_no_selector ".circle-refresh-action", visible: true
    assert_empty severe_browser_logs
  end

  test "protects a validation draft from a later WebSocket refresh" do
    visit_selected_reflection
    install_circle_realtime_signals!

    invalid_draft = "   "
    find(".circle-thread-compose-form textarea").set(invalid_draft)
    find(".circle-thread-send").click

    assert_selector ".circle-thread-compose-error", visible: true
    assert_selector ".circle-thread-compose-form[data-has-draft='true']"
    assert wait_for_circle_realtime_signal("loads"), page.evaluate_script("window.circleRealtimeSignals")
    page.execute_script("window.circleRealtimeSignals = { refreshes: 0, loads: 0 }")
    field = find(".circle-thread-compose-form textarea")
    assert_equal invalid_draft, field.value
    page.execute_script("arguments[0].blur()", field)

    external_reply = publish_circle_post(
      person: @other_member,
      reference: @reflection.scripture_circle_thread.reference,
      kind: "reply",
      parent_id: @reflection.id,
      body: "Je garde cette parole près de moi lorsque ma foi semble petite."
    )

    assert wait_for_circle_realtime_signal("refreshes"), page.evaluate_script("window.circleRealtimeSignals")
    assert wait_without_circle_frame_load, page.evaluate_script("window.circleRealtimeSignals")
    assert_selector ".circle-refresh-action", text: I18n.t("scripture_circle.inbox.refresh", locale: :fr), visible: true
    assert_selector ".circle-thread-compose-error", visible: true
    assert_equal invalid_draft, find(".circle-thread-compose-form textarea").value
    assert_no_selector ".circle-thread-message", text: external_reply.body
    assert_empty severe_browser_logs.reject { |entry| expected_circle_validation_response?(entry) }
  end

  test "automatically renders an external reply when no composer draft needs protection" do
    visit_selected_reflection
    install_circle_realtime_signals!

    external_reply = publish_circle_post(
      person: @other_member,
      reference: @reflection.scripture_circle_thread.reference,
      kind: "reply",
      parent_id: @reflection.id,
      body: "La semence grandit parfois avant que je puisse la voir."
    )

    assert wait_for_circle_realtime_signal("refreshes"), page.evaluate_script("window.circleRealtimeSignals")
    assert wait_for_circle_realtime_signal("loads"), page.evaluate_script("window.circleRealtimeSignals")
    assert_selector ".circle-thread-message", text: external_reply.body
    assert_no_selector ".circle-refresh-action", visible: true
    assert_empty severe_browser_logs
  end

  test "publishes a reply in the selected Circle thread without sending the member to the reader" do
    visit_selected_reflection

    reply = "Merci pour cette réflexion : elle m’aide à avancer un pas après l’autre."
    find(".circle-thread-compose-form textarea").set(reply)
    find(".circle-thread-send").click

    assert_selector ".circle-thread-message.is-own.is-new-arrival", text: reply
    assert_selector ".circle-workspace.is-thread-open"
    assert_selector ".circle-thread-heading h2", text: "Alma 32"
    assert_selector ".circle-thread-compose-form textarea", visible: true
    assert_equal "", find(".circle-thread-compose-form textarea").value
    assert_equal @reflection.id.to_s, page.evaluate_script("new URL(window.location.href).searchParams.get('conversation')")
    assert_empty severe_browser_logs
  end

  test "publishing a reply keeps the conversation anchored without a page jump" do
    12.times do |index|
      publish_circle_post(
        person: index.even? ? @author : @other_member,
        reference: @reflection.scripture_circle_thread.reference,
        kind: "reply",
        parent_id: @reflection.id,
        body: "Contribution #{index + 1} : je garde cette parole dans le fil pour éprouver sa continuité."
      )
    end

    visit_selected_reflection(width: 390, height: 844)
    page.execute_script("window.scrollTo(0, document.documentElement.scrollHeight)")

    before = page.evaluate_script(<<~JS)
      (function() {
        var composer = document.querySelector('.circle-thread-composer');
        window.circleReplyDiagnostics = {
          loads: 0,
          refreshPostIds: []
        };
        document.querySelector('#circle_live_feed').addEventListener('turbo:frame-load', function() {
          window.circleReplyDiagnostics.loads += 1;
        });
        document.querySelector('#circle_index').addEventListener('circle:refresh', function(event) {
          window.circleReplyDiagnostics.refreshPostIds.push(event.detail && event.detail.postId);
        });
        window.circlePostScrollMinimum = window.scrollY;
        window.circlePostScrollListener = function() {
          window.circlePostScrollMinimum = Math.min(window.circlePostScrollMinimum, window.scrollY);
        };
        window.addEventListener('scroll', window.circlePostScrollListener, { passive: true });
        return { scrollY: window.scrollY, composerTop: composer.getBoundingClientRect().top };
      })()
    JS

    reply = "Cette réponse doit apparaître sans déplacer brutalement la conversation."
    find(".circle-thread-compose-form textarea").set(reply)
    find(".circle-thread-send").click

    assert_selector ".circle-thread-message.is-own.is-new-arrival", text: reply
    assert_selector ".circle-workspace.is-thread-open"
    assert_no_selector ".circle-inbox", visible: true
    page.driver.browser.execute_async_script(<<~JS)
      var done = arguments[0];
      window.requestAnimationFrame(function() {
        window.requestAnimationFrame(function() { window.setTimeout(done, 70); });
      });
    JS
    after = page.evaluate_script(<<~JS)
      (function() {
        window.removeEventListener('scroll', window.circlePostScrollListener);
        var arrival = document.querySelector('.circle-thread-message.is-new-arrival');
        return {
          scrollY: window.scrollY,
          minimumScrollY: window.circlePostScrollMinimum,
          composerTop: document.querySelector('.circle-thread-composer').getBoundingClientRect().top,
          messageTop: arrival && arrival.getBoundingClientRect().top,
          messageBottom: arrival && arrival.getBoundingClientRect().bottom,
          arrivalId: arrival && arrival.id.replace('circle-message-', ''),
          arrivalCount: document.querySelectorAll('.circle-thread-message.is-new-arrival').length,
          diagnostics: window.circleReplyDiagnostics,
          viewportHeight: window.innerHeight
        };
      })()
    JS
    capture_circle_reply_screenshot if ENV["CIRCLE_SCREENSHOT"] == "1"

    assert_operator before.fetch("scrollY"), :>, 0, before.inspect
    assert_equal 1, after.fetch("diagnostics").fetch("loads"), after.inspect
    assert_equal 1, after.fetch("arrivalCount"), after.inspect
    assert_equal [ after.fetch("arrivalId") ], after.fetch("diagnostics").fetch("refreshPostIds"), after.inspect
    assert_operator after.fetch("minimumScrollY"), :>=, before.fetch("scrollY") - 2, { before:, after: }.inspect
    assert_in_delta before.fetch("composerTop"), after.fetch("composerTop"), 3, { before:, after: }.inspect
    assert_operator after.fetch("messageTop"), :<, after.fetch("viewportHeight"), after.inspect
    assert_operator after.fetch("messageBottom"), :>, 0, after.inspect
    assert_operator after.fetch("messageBottom"), :<=, after.fetch("composerTop") + 2, after.inspect
    assert_empty severe_browser_logs
  end

  private

    def capture_circle_reply_screenshot
      directory = Rails.root.join("tmp/street-shots/scripture-circle-motion")
      FileUtils.mkdir_p(directory)
      save_screenshot directory.join("forum-reply-inserted-390x844.png")
    end

    def visit_selected_reflection(width: 1440, height: 900)
      set_system_viewport(width, height)
      visit scripture_circle_path(locale: "fr", view: "recent", conversation: @reflection.id)

      assert_turbo_cable_stream_source [ @ward, ScriptureCircles::RamaRefresh::STREAM ], connected: true
      assert_selector ".circle-workspace.is-thread-open"
      assert_selector ".circle-thread-heading h2", text: "Alma 32"
      assert_selector ".circle-thread-compose-form textarea", visible: true
    end

    def install_circle_realtime_signals!
      page.execute_script(<<~JS)
        window.circleRealtimeSignals = { refreshes: 0, loads: 0 };
        document.querySelector('#circle_index').addEventListener('circle:refresh', function() {
          window.circleRealtimeSignals.refreshes += 1;
        });
        document.querySelector('#circle_live_feed').addEventListener('turbo:frame-load', function() {
          window.circleRealtimeSignals.loads += 1;
        });
      JS
    end

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
      visit "/favicon-32.png"
      session.cookies.to_hash.each do |name, value|
        page.driver.browser.manage.add_cookie(name:, value:, path: "/")
      end
    end

    def wait_for_circle_realtime_signal(key)
      page.driver.browser.execute_async_script(<<~JS)
        var done = arguments[0];
        var startedAt = performance.now();
        (function poll() {
          if (window.circleRealtimeSignals && window.circleRealtimeSignals[#{key.to_json}] > 0) return done(true);
          if (performance.now() - startedAt > 5000) return done(false);
          window.setTimeout(poll, 25);
        })();
      JS
    end

    def wait_without_circle_frame_load
      page.driver.browser.execute_async_script(<<~JS)
        var done = arguments[0];
        window.setTimeout(function() {
          done(window.circleRealtimeSignals && window.circleRealtimeSignals.loads === 0);
        }, 350);
      JS
    end

    def severe_browser_logs
      page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
        .reject { |entry| entry.message.include?("/favicon.ico") && entry.message.include?("404") }
    end

    def expected_circle_validation_response?(entry)
      entry.message.include?("/escrituras/cercle/messages") && entry.message.include?("422")
    end
end
