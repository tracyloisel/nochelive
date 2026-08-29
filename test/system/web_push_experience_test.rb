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
      assert_selector "button[data-category=challenges][role=switch][aria-checked=false]"
      assert_no_text person.given_name, exact: true

      scroll_to(find(".push-settings"))
      assert_settings_layout
      page.save_screenshot(SHOT_DIR.join("settings-default-390x844.png"))

      set_system_viewport(768, 1024)
      scroll_to(find(".push-settings"))
      assert_selector ".push-category-list > .push-category-card", count: 3
      assert_settings_layout
      page.save_screenshot(SHOT_DIR.join("settings-default-768x1024.png"))

      set_system_viewport(1440, 900)
      scroll_to(find(".push-settings"))
      assert_selector ".push-category-list > .push-category-card", count: 3
      assert_settings_layout
      page.save_screenshot(SHOT_DIR.join("settings-default-1440x900.png"))

      set_system_viewport(390, 844)
      scroll_to(find(".push-settings"))

      find("button[data-category=nights][aria-checked=false]").click
      assert_text I18n.t("notifications.settings.saved")
      assert_equal 1, page.evaluate_script("window.__pushPermissionRequests")
      assert person.notification_preference.reload.nights_enabled?
      refute person.notification_preference.challenges_enabled?
      refute person.notification_preference.verses_enabled?

      find("button[data-category=challenges][aria-checked=false]").click
      assert_text I18n.t("notifications.settings.saved")
      assert_selector "button[data-category=challenges][aria-checked=true]"
      assert_equal 1, page.evaluate_script("window.__pushPermissionRequests")
      assert person.notification_preference.reload.challenges_enabled?
      refute person.notification_preference.verses_enabled?
      assert_equal 1, person.web_push_subscriptions.active.count

      select I18n.t("notifications.settings.daily"), from: I18n.t("notifications.settings.frequency")
      fill_in I18n.t("notifications.settings.time"), with: "07:30"
      assert_field I18n.t("notifications.settings.time"), with: "07:30"
      find("button[data-category=verses][aria-checked=false]").click
      assert_selector "button[data-category=verses][aria-checked=true]"
      assert person.notification_preference.reload.verses_enabled?
      assert_equal "daily", person.notification_preference.verse_frequency
      assert_equal 1, page.evaluate_script("window.__pushPermissionRequests")

      find("button[data-category=challenges][aria-checked=true]").click
      assert_selector "button[data-category=challenges][aria-checked=false]"
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
      person = create_push_profile("Tracy")
      person.update!(ward: wards(:demo))
      page.driver.browser.manage.add_cookie(name: Locale::COOKIE, value: "fr")

      I18n.with_locale(:fr) do
        send_first_named_challenge

        assert_selector ".push-invitation.is-challenges", visible: true
        assert_selector ".push-invitation .btn-gold", count: 1
        assert_equal "none", find(".push-invitation").style("animation-name").fetch("animation-name")
        scroll_to(find(".push-invitation"))
        assert_challenge_prompt_layout
        page.save_screenshot(SHOT_DIR.join("challenge-invitation-reduced-motion-390x844.png"))

        set_system_viewport(768, 1024)
        scroll_to(find(".push-invitation"))
        assert_challenge_prompt_layout
        page.save_screenshot(SHOT_DIR.join("challenge-invitation-reduced-motion-768x1024.png"))

        set_system_viewport(1440, 900)
        scroll_to(find(".push-invitation"))
        assert_challenge_prompt_layout
        page.save_screenshot(SHOT_DIR.join("challenge-invitation-reduced-motion-1440x900.png"))

        set_system_viewport(390, 844)
        scroll_to(find(".push-invitation"))

        click_button I18n.t("notifications.prompt.not_now")
        assert_no_selector ".push-invitation", visible: true
      end
      state = person.person_devices.last.notification_prompt_states.find_by!(category: "challenges")
      assert_in_delta 30.days.from_now.to_i, state.snoozed_until.to_i, 5
    end
  end

  test "a challenge invitation disappears after this device activates alerts" do
    with_web_push_enabled do
      install_push_stubs
      person = create_push_profile("Défi Push")
      person.update!(ward: wards(:demo))

      send_first_named_challenge

      assert_selector ".banner", visible: true
      sleep 0.85
      [ [ 390, 844 ], [ 768, 1024 ], [ 1440, 900 ] ].each do |width, height|
        set_system_viewport(width, height)
        assert_banner_layout
        page.save_screenshot(SHOT_DIR.join("banner-celestial-dark-#{width}x#{height}.png"))
      end
      set_system_viewport(390, 844)

      assert_selector ".push-invitation.is-challenges + #inviter.is-friends", visible: true
      find(".push-invitation.is-challenges .push-primary").click

      assert_selector ".push-invitation.is-challenges.is-complete", visible: true
      page.save_screenshot(SHOT_DIR.join("challenge-invitation-activated-390x844.png"))
      assert_no_selector ".push-invitation.is-challenges", visible: true
      assert person.notification_preference.reload.challenges_enabled?
      assert_equal 1, person.web_push_subscriptions.active.count

      visit street_challenges_path
      assert_no_selector ".push-invitation.is-challenges", visible: true
    end
  end

  test "the glass confirmation stays luminous and clear on the Celestial Light profile" do
    person = create_push_profile("Luz Fluor")
    visit street_profile_path(edit: 1)
    fill_in I18n.t("street.edit_name"), with: person.given_name
    click_button I18n.t("street.save_profile")

    assert_selector "body.is-paper-hall"
    assert_selector ".banner", text: I18n.t("flashes.profile_updated"), visible: true
    sleep 0.85

    [ [ 390, 844 ], [ 768, 1024 ], [ 1440, 900 ] ].each do |width, height|
      set_system_viewport(width, height)
      assert_banner_layout
      page.save_screenshot(SHOT_DIR.join("banner-celestial-light-#{width}x#{height}.png"))
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

      set_system_viewport(768, 1024)
      scroll_to(find(".push-invitation.is-nights"))
      assert_selector ".push-invitation.is-nights .push-primary", visible: true
      page.save_screenshot(SHOT_DIR.join("night-invitation-768x1024.png"))

      set_system_viewport(1440, 900)
      scroll_to(find(".push-invitation.is-nights"))
      assert_selector ".push-invitation.is-nights .push-primary", visible: true
      page.save_screenshot(SHOT_DIR.join("night-invitation-1440x900.png"))

      set_system_viewport(390, 844)
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

      send_first_named_challenge

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

    def send_first_named_challenge
      visit street_challenges_path
      assert_no_selector ".push-invitation.is-challenges", visible: true
      form = find(".duel-campus-friends form.duel-campus-friend-form", match: :first)
      scroll_to(form)
      form.find("button[type=submit]").click
      assert_current_path street_challenges_path
    end

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

    def assert_settings_layout
      metrics = page.evaluate_script(<<~JS)
        (() => {
          const root = document.documentElement;
          const list = document.querySelector(".push-category-list");
          const cards = [...document.querySelectorAll(".push-category-card")];
          const controls = [...document.querySelectorAll(".push-setting-toggle:not([hidden])")];
          const listRect = list.getBoundingClientRect();
          const cardRects = cards.map((card) => card.getBoundingClientRect());
          const controlRects = controls.map((control) => control.getBoundingClientRect());
          return {
            noHorizontalOverflow: root.scrollWidth <= window.innerWidth,
            singleColumn: new Set(cardRects.map((rect) => Math.round(rect.left))).size === 1,
            cardsContained: cardRects.every((rect) => rect.left >= listRect.left - 1 && rect.right <= listRect.right + 1),
            controlsContained: controlRects.every((rect) => cardRects.some((card) => rect.left >= card.left - 1 && rect.right <= card.right + 1)),
            controlsReachable: controlRects.every((rect) => rect.height >= 44),
            controlsCompact: controlRects.every((rect) => rect.height <= 48),
            cardCount: cards.length
          };
        })()
      JS

      assert_equal 3, metrics.fetch("cardCount")
      assert metrics.fetch("noHorizontalOverflow"), "notification settings overflow horizontally"
      assert metrics.fetch("singleColumn"), "notification categories must remain one measured column"
      assert metrics.fetch("cardsContained"), "a notification category escapes the settings folio"
      assert metrics.fetch("controlsContained"), "a notification switch escapes its category"
      assert metrics.fetch("controlsReachable"), "notification switches must retain a 44px target"
      assert metrics.fetch("controlsCompact"), "notification switches must not grow into multiline CTAs"
    end

    def assert_challenge_prompt_layout
      metrics = page.evaluate_script(<<~JS)
        (() => {
          const root = document.documentElement;
          const card = document.querySelector(".push-invitation.is-challenges");
          const title = card.querySelector("h2");
          const mark = card.querySelector(".push-invitation-mark");
          const copy = card.querySelector(".push-invitation-copy");
          const primary = card.querySelector(".push-primary:not([hidden])");
          const quiet = card.querySelector(".quiet-link");
          const status = card.querySelector(".push-device-state");
          const feedback = card.querySelector(".push-feedback");
          const cardRect = card.getBoundingClientRect();
          const contained = (element) => {
            const rect = element.getBoundingClientRect();
            return rect.left >= cardRect.left - 1 && rect.right <= cardRect.right + 1;
          };
          return {
            noHorizontalOverflow: root.scrollWidth <= window.innerWidth,
            cardWidth: Math.round(cardRect.width),
            parentWidth: Math.round(card.parentElement.getBoundingClientRect().width),
            parentClass: card.parentElement.className,
            gridColumn: getComputedStyle(card).gridColumn,
            alignItems: getComputedStyle(card).alignItems,
            gridTemplateColumns: getComputedStyle(card).gridTemplateColumns,
            gridTemplateRows: getComputedStyle(card).gridTemplateRows,
            children: [...card.children].map((child) => ({
              className: child.className,
              display: getComputedStyle(child).display,
              position: getComputedStyle(child).position,
              gridColumn: getComputedStyle(child).gridColumn,
              gridRow: getComputedStyle(child).gridRow,
              height: Math.round(child.getBoundingClientRect().height)
            })),
            computedHeight: getComputedStyle(card).height,
            computedMinHeight: getComputedStyle(card).minHeight,
            cardTop: Math.round(cardRect.top),
            cardHeight: Math.round(cardRect.height),
            markTop: Math.round(mark.getBoundingClientRect().top),
            copyTop: Math.round(copy.getBoundingClientRect().top),
            titleContained: contained(title),
            primaryContained: contained(primary),
            statusContained: contained(status),
            feedbackHidden: getComputedStyle(feedback).display === "none",
            compact: cardRect.height <= (window.innerWidth < 760 ? 520 : 360),
            primaryReachable: primary.getBoundingClientRect().height >= 44,
            quietReachable: quiet.getBoundingClientRect().height >= 44,
            titleVisible: title.scrollHeight <= title.clientHeight + 4
          };
        })()
      JS

      assert metrics.fetch("noHorizontalOverflow"), "challenge notification overflows horizontally"
      assert metrics.fetch("titleContained"), "challenge notification title escapes its panel"
      assert metrics.fetch("primaryContained"), "challenge notification CTA escapes its panel: #{metrics.inspect}"
      assert metrics.fetch("statusContained"), "challenge notification status escapes its panel"
      assert metrics.fetch("feedbackHidden"), "empty challenge notification feedback must not reserve space"
      assert metrics.fetch("compact"), "challenge notification panel leaves too much empty space: #{metrics.inspect}"
      assert metrics.fetch("primaryReachable"), "challenge notification CTA must retain a 44px target"
      assert metrics.fetch("quietReachable"), "challenge notification dismissal must retain a 44px target"
      assert metrics.fetch("titleVisible"), "challenge notification title is clipped: #{metrics.inspect}"
    end

    def assert_banner_layout
      metrics = page.evaluate_script(<<~JS)
        (() => {
          const banner = document.querySelector(".banner");
          const menu = document.querySelector(".home-menu-btn");
          const rect = banner.getBoundingClientRect();
          const menuRect = menu?.getBoundingClientRect();
          const style = getComputedStyle(banner);
          const transform = new DOMMatrixReadOnly(style.transform === "none" ? undefined : style.transform);
          const copy = banner.querySelector(".banner-copy");
          const copyRect = copy.getBoundingClientRect();
          const textRange = document.createRange();
          textRange.selectNodeContents(copy);
          const textRect = textRange.getBoundingClientRect();
          return {
            noHorizontalOverflow: document.documentElement.scrollWidth <= window.innerWidth,
            clearOfChrome: !menuRect || rect.top >= menuRect.bottom + 16,
            width: Math.round(rect.width),
            height: Math.round(rect.height),
            animationName: style.animationName,
            backdropFilter: style.backdropFilter || style.webkitBackdropFilter,
            borderColor: style.borderColor,
            verticalOffset: transform.m42,
            textVisible: textRect.top >= copyRect.top - 2 &&
              textRect.right <= copyRect.right + 2 &&
              textRect.bottom <= copyRect.bottom + 2 &&
              textRect.left >= copyRect.left - 2
          };
        })()
      JS

      assert metrics.fetch("noHorizontalOverflow"), "notification banner overflows horizontally"
      assert metrics.fetch("clearOfChrome"), "notification banner overlaps the page chrome: #{metrics.inspect}"
      assert_operator metrics.fetch("width"), :<=, 480
      assert_operator metrics.fetch("height"), :>=, 44
      assert_includes metrics.fetch("animationName"), "banner-bloom"
      assert_in_delta 0, metrics.fetch("verticalOffset"), 0.1, "notification banner must not move the screen vertically"
      assert_includes metrics.fetch("backdropFilter"), "blur(36px)"
      refute_equal "rgba(0, 0, 0, 0)", metrics.fetch("borderColor")
      assert metrics.fetch("textVisible"), "notification banner text is clipped"
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
