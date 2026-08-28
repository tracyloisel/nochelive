require "application_system_test_case"

class WebPushExperienceTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/push-shots")

  setup { FileUtils.mkdir_p(SHOT_DIR) }

  teardown do
    page.driver.browser.execute_cdp(
      "Emulation.setEmulatedMedia",
      media: "screen",
      features: [ { name: "prefers-reduced-motion", value: "no-preference" } ]
    ) if self.class.chrome_binary
    if @injected_script_id && self.class.chrome_binary
      page.driver.browser.execute_cdp(
        "Page.removeScriptToEvaluateOnNewDocument",
        identifier: @injected_script_id
      )
    end
  rescue Selenium::WebDriver::Error::WebDriverError
    nil
  end

  test "the voluntary ficha flow activates categories separately and disconnects only this device" do
    with_web_push_enabled do
      install_push_stubs
      person = create_push_profile("Flujo Push")
      visit street_profile_path(edit: 1)

      assert_selector ".push-settings"
      assert_text I18n.t("notifications.settings.device_default")
      assert_selector "button[data-category=challenges]", text: person.given_name

      find("button[data-category=nights]", text: person.given_name).click
      assert_text I18n.t("notifications.settings.saved")
      assert_equal 1, page.evaluate_script("window.__pushPermissionRequests")
      assert person.notification_preference.reload.nights_enabled?
      refute person.notification_preference.challenges_enabled?
      refute person.notification_preference.verses_enabled?

      find("button[data-category=challenges]", text: person.given_name).click
      assert_text I18n.t("notifications.settings.saved")
      assert_equal 1, page.evaluate_script("window.__pushPermissionRequests")
      assert person.notification_preference.reload.challenges_enabled?
      refute person.notification_preference.verses_enabled?
      assert_equal 1, person.web_push_subscriptions.active.count

      select I18n.t("notifications.settings.daily"), from: I18n.t("notifications.settings.frequency")
      fill_in I18n.t("notifications.settings.time"), with: "07:30"
      assert_selector "button[data-category=verses]", text: /07:30/
      find("button[data-category=verses]", text: /07:30/).click
      assert_selector "button[data-category=verses]", text: I18n.t("notifications.settings.verses_disable", name: person.given_name)
      assert person.notification_preference.reload.verses_enabled?
      assert_equal "daily", person.notification_preference.verse_frequency
      assert_equal 1, page.evaluate_script("window.__pushPermissionRequests")

      find("button[data-category=challenges]", text: I18n.t("notifications.settings.challenges_disable", name: person.given_name)).click
      assert_selector "button[data-category=challenges]", text: I18n.t("notifications.settings.challenges_enable", name: person.given_name)
      refute person.notification_preference.reload.challenges_enabled?
      assert person.notification_preference.verses_enabled?

      scroll_to(find(".push-settings"))
      sleep 0.45
      page.save_screenshot(SHOT_DIR.join("settings-authorized-390x844.png"))

      click_button I18n.t("notifications.settings.disable_device")
      assert_text I18n.t("notifications.settings.disabled_device")
      assert_empty person.web_push_subscriptions.reload
      assert person.notification_preference.reload.verses_enabled?
      assert_no_selector ".push-disable-device", visible: true
    end
  end

  test "a contextual invitation snoozes for thirty days and honors reduced motion" do
    with_web_push_enabled do
      install_push_stubs
      emulate_reduced_motion
      person = create_push_profile("Epilogo Push")
      person.update!(ward: wards(:demo))

      visit street_challenges_path

      assert_selector ".push-invitation.is-challenges", visible: true
      assert_selector ".push-invitation .btn-gold", count: 1
      assert_equal "none", find(".push-invitation").style("animation-name").fetch("animation-name")
      scroll_to(find(".push-invitation"))
      page.save_screenshot(SHOT_DIR.join("challenge-invitation-reduced-motion-390x844.png"))

      click_button I18n.t("notifications.prompt.not_now")
      assert_no_selector ".push-invitation", visible: true
      state = person.person_devices.last.notification_prompt_states.find_by!(category: "challenges")
      assert_in_delta 30.days.from_now.to_i, state.snoozed_until.to_i, 5
    end
  end

  test "the upcoming live card asks once and activates only Noche Live reminders" do
    with_web_push_enabled do
      install_push_stubs
      person = create_push_profile("Noche Push")
      person.update!(ward: wards(:demo))
      visit street_leaderboard_path
      game_sessions(:david).update!(status: "finished")
      game_sessions(:elias).update!(starts_at: 18.hours.from_now)

      visit root_path

      assert_selector ".hub-live.is-imminent"
      assert_selector ".push-invitation.is-nights", visible: true
      scroll_to(find(".push-invitation.is-nights"))
      assert_selector ".push-invitation.is-nights .btn-gold", count: 1
      assert_no_selector ".push-invitation.is-challenges", visible: true
      assert_no_selector ".push-invitation.is-verses", visible: true
      page.save_screenshot(SHOT_DIR.join("night-invitation-390x844.png"))

      page.driver.browser.manage.window.resize_to(768, 1024)
      scroll_to(find(".push-invitation.is-nights"))
      assert_selector ".push-invitation.is-nights .push-primary", visible: true
      page.save_screenshot(SHOT_DIR.join("night-invitation-768x1024.png"))

      page.driver.browser.manage.window.resize_to(1440, 900)
      scroll_to(find(".push-invitation.is-nights"))
      assert_selector ".push-invitation.is-nights .push-primary", visible: true
      page.save_screenshot(SHOT_DIR.join("night-invitation-1440x900.png"))

      page.driver.browser.manage.window.resize_to(390, 844)
      scroll_to(find(".push-invitation.is-nights"))

      click_button I18n.t("notifications.prompt.nights_cta", name: person.given_name)

      assert_text I18n.t("notifications.settings.saved")
      assert_equal 1, page.evaluate_script("window.__pushPermissionRequests")
      assert person.notification_preference.reload.nights_enabled?
      refute person.notification_preference.challenges_enabled?
      refute person.notification_preference.verses_enabled?
      assert_equal root_path, URI.parse(page.current_url).path
    end
  end

  test "iPhone asks for installation now and never chains the push permission" do
    with_web_push_enabled do
      install_push_stubs(ios: true)
      person = create_push_profile("iPhone Flow")
      person.update!(ward: wards(:demo))

      visit street_challenges_path

      assert_selector ".push-invitation.is-install-required", visible: true
      assert_selector ".push-install", visible: true
      assert_no_selector ".push-primary", visible: true
      page.execute_script(<<~JS)
        window.NocheInstallPrompt = null;
        window.Stimulus.getControllerForElementAndIdentifier(document.body, "pwa-install").deferredPrompt = null;
      JS
      find(".push-install").click
      assert_selector ".pwa-install-dialog[open]"
      sleep 0.55
      assert_equal 0, page.evaluate_script("window.__pushPermissionRequests")
      assert_equal "challenges", page.evaluate_script("sessionStorage.getItem('noche:push-interest')")
      refute person.notification_settings.challenges_enabled?
      page.save_screenshot(SHOT_DIR.join("iphone-install-before-push-390x844.png"))
    end
  end

  test "a completed scripture journey receives a readable Celestial Dark epilogue" do
    with_web_push_enabled do
      install_push_stubs
      person = create_push_profile("Luz Push")
      run = create_final_study_run(person)

      visit study_run_path(run, reveal: run.current_answer.id)
      click_button I18n.t("study.finish")

      assert_selector "body.is-study-run.is-celestial-dark"
      assert_selector ".push-invitation.is-verses", visible: true
      assert_selector ".push-invitation .btn-gold", count: 1
      assert_selector ".push-invitation", text: person.given_name
      scroll_to(find(".push-invitation"))
      sleep 0.8
      page.save_screenshot(SHOT_DIR.join("verse-invitation-celestial-dark-390x844.png"))
    end
  end

  private

    def create_push_profile(name)
      visit street_profile_path
      fill_in I18n.t("street.create_who"), with: name
      find("form.profile-gate-new button[type=submit]").click
      assert_selector "body.is-street-hub"
      assert_no_selector ".push-invitation", visible: true
      Person.find_by!(given_name: name)
    end

    def install_push_stubs(ios: false)
      ios_script = if ios
        <<~JS
          Object.defineProperty(navigator, "userAgent", { configurable: true, get: () => "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 Version/18.0 Mobile Safari/604.1" });
          Object.defineProperty(navigator, "platform", { configurable: true, get: () => "iPhone" });
          Object.defineProperty(navigator, "maxTouchPoints", { configurable: true, get: () => 5 });
        JS
      end
      source = <<~JS
        (() => {
          let permission = "default";
          let subscription = null;
          window.__pushPermissionRequests = 0;
          const fakeSubscription = {
            endpoint: "https://push.example.test/system-flow",
            toJSON: () => ({ endpoint: "https://push.example.test/system-flow", keys: { p256dh: "system-p256dh", auth: "system-auth" } }),
            unsubscribe: async () => { subscription = null; return true; }
          };
          class FakeNotification {
            static get permission() { return permission; }
            static async requestPermission() { window.__pushPermissionRequests += 1; permission = "granted"; return permission; }
          }
          class FakePushManager {}
          Object.defineProperty(window, "Notification", { configurable: true, value: FakeNotification });
          Object.defineProperty(window, "PushManager", { configurable: true, value: FakePushManager });
          Object.defineProperty(navigator, "serviceWorker", { configurable: true, value: {
            ready: Promise.resolve({ pushManager: {
              getSubscription: async () => subscription,
              subscribe: async () => { subscription = fakeSubscription; return subscription; }
            } }),
            register: async () => ({}),
            addEventListener: () => {},
            removeEventListener: () => {}
          } });
          #{ios_script}
        })();
      JS
      result = page.driver.browser.execute_cdp("Page.addScriptToEvaluateOnNewDocument", source:)
      @injected_script_id = result.fetch("identifier")
    end

    def emulate_reduced_motion
      page.driver.browser.execute_cdp(
        "Emulation.setEmulatedMedia",
        media: "screen",
        features: [ { name: "prefers-reduced-motion", value: "reduce" } ]
      )
    end

    def create_final_study_run(person)
      program = StudyProgram.create!(
        slug: "push-visual-study", title: "Push visual study", year: 2026,
        canon: "old_testament", locale: "es", status: "published",
        source_url: "https://example.test/push-visual-study"
      )
      unit = program.study_units.create!(
        slug: "push-visual-week", kind: "week", position: 1,
        title: "Psalms 49–86", source_url: "https://example.test/push-visual-study/week",
        status: "published"
      )
      content = YAML.safe_load_file(Rails.root.join("config/study/come_follow_me_2026.yml"))
        .dig("quizzes", 0, "content")
      quiz = unit.study_quiz_versions.create!(
        version: 1, status: "published", editorial_locale: "fr", content:,
        content_digest: Digest::SHA256.hexdigest(content.to_json)
      )
      run = StudyRun.create!(
        person:, study_quiz_version: quiz, device_digest: "push-system-study",
        position: 10, score: 9, status: "open", opened_at: 1.hour.ago
      )
      question = quiz.question_at(10)
      run.study_answers.create!(
        question_key: question.fetch("key"), choice_key: question.fetch("correct_choice"), correct: true
      )
      run
    end
end
