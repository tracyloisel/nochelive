require "application_system_test_case"

class StreetProfileVisualTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/street-shots/profile-dashboard")

  test "profile dashboard and first-name editor stay clear across viewports" do
    sign_in_fixture_person_direct!(people(:pili))
    problem_browser_logs

    [ [ 390, 844 ], [ 768, 1024 ], [ 1440, 900 ] ].each do |width, height|
      set_system_viewport(width, height)
      visit player_profile_path(people(:pili))

      assert_selector ".profile-dashboard"
      assert_selector ".profile-dashboard-hero", text: people(:pili).given_name
      assert_selector ".profile-stage > .profile-switch-player[href='#{street_profile_path(not_me: 1)}']", text: I18n.t("street.switch_profile")
      assert_button I18n.t("street.sign_out"), class: "profile-glass-secondary"
      assert_selector "a.profile-field-row[href='#{player_profile_path(people(:pili), edit: "given_name")}']"
      assert_selector ".profile-field-row[data-profile-field=player_id]", text: people(:pili).id.to_s
      assert_selector ".profile-field-row[data-profile-field=created_at]",
                      text: I18n.l(people(:pili).created_at.to_date, format: :default)
      assert_selector "a.profile-destination-card[href='#{scripture_library_path(section: "bookmarks", anchor: "selection")}']", text: I18n.t("street.profile_dashboard.word_title")
      assert_profile_geometry!
      assert_dashboard_motion_contract! if width == 390
      shot("profile-#{width}x#{height}")

      scroll_to(find("button.street-sign-out"))
      shot("profile-sign-out-#{width}x#{height}")

      visit player_profile_path(people(:pili), edit: "given_name")
      assert_selector ".profile-editor-sheet[role=dialog][aria-modal=true]"
      assert_no_selector ".profile-editor-handle"
      assert_field I18n.t("street.profile_dashboard.given_name"), with: people(:pili).given_name
      assert_button I18n.t("street.profile_dashboard.save")
      assert_editor_geometry!
      assert_editor_motion_contract! if width == 390
      settle_profile_motion
      shot("profile-first-name-#{width}x#{height}")
      assert_empty problem_browser_logs

      if width == 390
        fill_in I18n.t("street.profile_dashboard.given_name"), with: "Pilar"
        assert_selector ".profile-editor-count", text: "5/24"
        find(".profile-editor-actions .profile-glass-secondary").click
        assert_current_path player_profile_path(people(:pili))
        assert_equal "given_name", page.evaluate_script("document.activeElement.dataset.profileEditorField")
      end
    end
  end

  test "editor restores focus after escape and confirms a saved field locally" do
    person = people(:pili)
    sign_in_fixture_person_direct!(person)
    problem_browser_logs
    set_system_viewport(390, 844)

    visit player_profile_path(person, edit: "given_name")
    find("body").send_keys(:escape)
    assert_current_path player_profile_path(person)
    assert_equal "given_name", page.evaluate_script("document.activeElement.dataset.profileEditorField")

    visit player_profile_path(person, edit: "given_name")
    fill_in I18n.t("street.profile_dashboard.given_name"), with: "Pilar Motion"
    click_button I18n.t("street.profile_dashboard.save")

    assert_current_path player_profile_path(person)
    assert_selector ".profile-field-row[data-profile-editor-field=given_name].is-saved"
    assert_equal "given_name", page.evaluate_script("document.activeElement.dataset.profileEditorField")
    assert_equal "Pilar Motion", person.reload.given_name
    shot("profile-success-390x844")
    assert_empty problem_browser_logs
  end

  test "word row opens personal passages inside the scripture library" do
    sign_in_fixture_person_direct!(people(:pili))
    visit player_profile_path(people(:pili))

    find("a.profile-destination-card[href='#{scripture_library_path(section: "bookmarks", anchor: "selection")}']").click

    assert_current_path scripture_library_path(section: "bookmarks", anchor: "selection")
    assert_selector ".scripture-library"
    assert_selector "#library_selection"
    assert_selector "a.navigation-dock__item.is-active[aria-current='page'][href='#{scripture_library_path}']"
  end

  test "personal answer history stays readable and private across viewports" do
    person = people(:pili)
    run = quiz_runs(:pili_coronas)
    pack = QuizDefinition.catalog.find_pack(run.pack_id)
    first = pack.question_at(1)
    second = pack.question_at(2)
    third = pack.question_at(3)
    wrong_choice = second.choices.find { |choice| choice.fetch("key") != second.correct_choice }.fetch("key")
    [
      [ first, first.correct_choice, true, 1_700 ],
      [ second, wrong_choice, false, 9_400 ],
      [ third, nil, false, nil ]
    ].each do |question, choice_key, correct, duration_ms|
      run.quiz_answers.create!(
        device_digest: run.device_digest,
        pack_id: run.pack_id,
        question_id: question.id,
        choice_key:,
        correct:,
        duration_ms:
      )
    end
    sign_in_fixture_person_direct!(person)
    problem_browser_logs

    [ [ 390, 844 ], [ 768, 1024 ], [ 1440, 900 ] ].each do |width, height|
      set_system_viewport(width, height)
      visit player_profile_path(person)
      assert_selector "a.profile-destination-card[href='#{player_quiz_history_path(person)}']",
                      text: I18n.t("street.profile_dashboard.answers_title")
      find("a.profile-destination-card[href='#{player_quiz_history_path(person)}']").click

      assert_current_path player_quiz_history_path(person)
      assert_selector "body.is-profile-answer-history"
      assert_selector ".profile-answer-overview", text: "3"
      assert_selector ".profile-answer-row.is-correct", count: 1
      assert_selector ".profile-answer-row.is-wrong", count: 2
      assert_selector ".profile-answer-duration", text: /1[,.]7/
      assert_selector ".profile-answer-duration", text: /9[,.]4/
      assert_text I18n.t("street.quiz_history.time_unknown")
      assert_text I18n.t("street.quiz_history.your_answer")
      assert_text I18n.t("street.quiz_history.correct_answer")
      assert_selector "a.navigation-dock__item.is-active[aria-current='page'][href='#{player_profile_path(person)}']"
      assert_answer_history_geometry!
      assert_answer_history_motion_contract! if width == 390
      shot("profile-answer-history-#{width}x#{height}")

      scroll_to(find(".profile-answer-row.is-wrong", match: :first))
      shot("profile-answer-history-detail-#{width}x#{height}")
      assert_empty problem_browser_logs
    end

    sign_in_fixture_person_direct!(people(:carmen_lopez))
    set_system_viewport(390, 844)
    visit player_quiz_history_path(people(:carmen_lopez))
    assert_selector ".profile-answer-empty"
    assert_selector ".profile-answer-session", count: 0
    assert_link I18n.t("street.quiz_history.empty_action"), href: street_map_path
    assert_answer_history_geometry!(empty: true)
    shot("profile-answer-history-empty-390x844")
    assert_empty problem_browser_logs
  end

  test "minimal long translated and fallback states remain usable" do
    person = people(:pili)
    sign_in_fixture_person_direct!(person)
    problem_browser_logs
    long_name = "ABCDEFGHIJKLMNOPQRSTUVWX"
    person.update!(given_name: long_name, family_name: long_name)
    person.ward.update!(
      name: "Rama de la Comunidad Internacional de la Costa Mediterránea",
      city: nil,
      country_name: nil
    )
    set_system_viewport(390, 844)

    Locale::AVAILABLE.each do |locale|
      visit player_profile_path(person, locale: Locale.i18n(locale))
      assert_selector "h1", text: I18n.t("street.profile_dashboard.title", locale: Locale.i18n(locale))
      assert_no_horizontal_overflow!
    end
    assert_selector "#profile-player-name", text: "#{long_name} #{long_name}", exact_text: true
    assert_selector ".profile-field-row strong", text: long_name, exact_text: true, count: 2
    assert_text person.ward.name
    assert_long_copy_wraps!
    shot("profile-long-copy-390x844")
    scroll_to(find("a.profile-destination-card[href='#{player_profile_path(person, ward_next: 1)}']"))
    shot("profile-long-ward-390x844")

    person.update!(given_name: "Luz", family_name: nil, favorite_year: nil, ward: nil)
    visit player_profile_path(person, locale: :es)
    assert_text I18n.t("street.profile_dashboard.not_set", locale: :es), count: 2
    assert_text I18n.t("street.profile_dashboard.no_ward", locale: :es)
    assert_no_horizontal_overflow!
    shot("profile-minimal-390x844")

    visit player_profile_path(person, edit: "given_name", locale: :es)
    page.execute_script('document.querySelector("input[name=given_name]").removeAttribute("required")')
    fill_in I18n.t("street.profile_dashboard.given_name", locale: :es), with: ""
    click_button I18n.t("street.profile_dashboard.save", locale: :es)
    assert_selector ".profile-editor-error[role=alert]"
    assert_field I18n.t("street.profile_dashboard.given_name", locale: :es), with: ""
    assert_selector "input[name=given_name][aria-describedby~='profile-editor-error']"
    settle_profile_motion(milliseconds: 400)
    shot("profile-error-390x844")
    validation_logs = problem_browser_logs
    assert_equal 1, validation_logs.size
    assert_includes validation_logs.first.message, "422 (Unprocessable Content)"

    visit player_profile_path(person, edit: "given_name", locale: :es)
    page.execute_script(<<~JS)
      document.querySelector(".profile-editor-form").addEventListener("submit", (event) => event.preventDefault(), { capture: true, once: true })
    JS
    click_button I18n.t("street.profile_dashboard.save", locale: :es)
    assert_selector ".profile-editor-backdrop.is-loading[aria-busy=true]"
    assert_selector ".profile-glass-primary:disabled"
    settle_profile_motion(milliseconds: 350)
    shot("profile-loading-390x844")

    emulate_profile_media(motion: "reduce", transparency: "reduce")
    visit player_profile_path(person, locale: :es)
    dashboard_fallback = page.evaluate_script(<<~JS)
      (() => {
        const hero = document.querySelector(".profile-dashboard-hero")
        const group = document.querySelector(".profile-dashboard-group")
        const row = document.querySelector(".profile-field-row")
        return {
          heroAnimation: getComputedStyle(hero).animationName,
          groupAnimation: getComputedStyle(group).animationName,
          heroBackdrop: getComputedStyle(hero).backdropFilter || getComputedStyle(hero).webkitBackdropFilter,
          rowTransition: getComputedStyle(row).transitionDuration
        }
      })()
    JS
    assert_equal "none", dashboard_fallback["heroAnimation"]
    assert_equal "none", dashboard_fallback["groupAnimation"]
    assert_equal "none", dashboard_fallback["heroBackdrop"]
    assert_equal "0s", dashboard_fallback["rowTransition"]

    visit player_profile_path(person, edit: "given_name", locale: :es)
    editor_fallback = page.evaluate_script(<<~JS)
      (() => {
        const backdrop = document.querySelector(".profile-editor-backdrop")
        const sheet = document.querySelector(".profile-editor-sheet")
        return {
          backdropAnimation: getComputedStyle(backdrop).animationName,
          sheetAnimation: getComputedStyle(sheet).animationName,
          backdropFilter: getComputedStyle(backdrop).backdropFilter || getComputedStyle(backdrop).webkitBackdropFilter,
          sheetBackdrop: getComputedStyle(sheet).backdropFilter || getComputedStyle(sheet).webkitBackdropFilter
        }
      })()
    JS
    assert_equal "none", editor_fallback["backdropAnimation"]
    assert_equal "none", editor_fallback["sheetAnimation"]
    assert_equal "none", editor_fallback["backdropFilter"]
    assert_equal "none", editor_fallback["sheetBackdrop"]
    assert_includes Rails.root.join("app/assets/stylesheets/surfaces/profile.css").read, "@supports not ((backdrop-filter: blur(1px))"
    assert_includes Rails.root.join("app/assets/stylesheets/application.css").read, "::view-transition-old(root)"
    assert_empty problem_browser_logs
  ensure
    emulate_profile_media(motion: "no-preference", transparency: "no-preference") if self.class.chrome_binary
  end

  private

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

    def assert_profile_geometry!
      geometry = page.evaluate_script(<<~JS)
        (function() {
          var dashboard = document.querySelector(".profile-dashboard").getBoundingClientRect();
          var hero = document.querySelector(".profile-dashboard-hero").getBoundingClientRect();
          var switchPlayer = document.querySelector(".profile-switch-player").getBoundingClientRect();
          var actions = document.querySelector(".profile-actions").getBoundingClientRect();
          var signOut = document.querySelector(".street-sign-out").getBoundingClientRect();
          var firstRow = document.querySelector(".profile-field-row").getBoundingClientRect();
          var heroStyle = getComputedStyle(document.querySelector(".profile-dashboard-hero"));
          return {
            dashboardLeft: dashboard.left,
            dashboardRight: dashboard.right,
            heroHeight: hero.height,
            switchPlayerBottom: switchPlayer.bottom,
            switchPlayerHeight: switchPlayer.height,
            heroTop: hero.top,
            actionsCenter: actions.left + actions.width / 2,
            signOutCenter: signOut.left + signOut.width / 2,
            signOutHeight: signOut.height,
            firstRowHeight: firstRow.height,
            heroBackdrop: heroStyle.backdropFilter || heroStyle.webkitBackdropFilter,
            viewportWidth: window.innerWidth,
            bodyOverflow: document.documentElement.scrollWidth > window.innerWidth + 1
          };
        })()
      JS

      assert_operator geometry["dashboardLeft"], :>=, -1
      assert_operator geometry["dashboardRight"], :<=, geometry["viewportWidth"] + 1
      assert_operator geometry["heroHeight"], :>=, 170
      assert_operator geometry["switchPlayerBottom"], :<, geometry["heroTop"]
      assert_operator geometry["switchPlayerHeight"], :>=, 43.9
      assert_in_delta geometry["actionsCenter"], geometry["signOutCenter"], 1
      assert_operator geometry["signOutHeight"], :>=, 43.9
      assert_operator geometry["firstRowHeight"], :>=, 48
      assert_match(/blur/, geometry["heroBackdrop"])
      assert_not geometry["bodyOverflow"]
    end

    def assert_dashboard_motion_contract!
      motion = page.evaluate_script(<<~JS)
        (() => ({
          hero: getComputedStyle(document.querySelector(".profile-dashboard-hero")).animationName,
          group: getComputedStyle(document.querySelector(".profile-dashboard-group")).animationName,
          medallion: getComputedStyle(document.querySelector(".profile-dashboard-group-heading img")).animationName
        }))()
      JS

      assert_equal "profile-dashboard-hero-enter", motion["hero"]
      assert_equal "profile-dashboard-group-enter", motion["group"]
      assert_equal "profile-dashboard-medallion-enter", motion["medallion"]
    end

    def assert_editor_motion_contract!
      motion = page.evaluate_script(<<~JS)
        (() => ({
          backdrop: getComputedStyle(document.querySelector(".profile-editor-backdrop")).animationName,
          sheet: getComputedStyle(document.querySelector(".profile-editor-sheet")).animationName
        }))()
      JS

      assert_equal "profile-editor-backdrop-enter", motion["backdrop"]
      assert_equal "profile-editor-sheet-enter", motion["sheet"]
    end

    def assert_answer_history_motion_contract!
      motion = page.evaluate_script(<<~JS)
        (() => ({
          overview: getComputedStyle(document.querySelector(".profile-answer-overview")).animationName,
          sessions: getComputedStyle(document.querySelector(".profile-answer-sessions")).animationName,
          row: getComputedStyle(document.querySelector(".profile-answer-row")).animationName
        }))()
      JS

      assert_equal "profile-answer-group-enter", motion["overview"]
      assert_equal "profile-answer-group-enter", motion["sessions"]
      assert_equal "none", motion["row"]
    end

    def assert_editor_geometry!
      geometry = page.evaluate_script(<<~JS)
        (function() {
          var sheet = document.querySelector(".profile-editor-sheet").getBoundingClientRect();
          var save = document.querySelector(".profile-glass-primary").getBoundingClientRect();
          var actions = [...document.querySelectorAll(".profile-editor-sheet a, .profile-editor-sheet button")].map((element) => element.getBoundingClientRect());
          return {
            sheetLeft: sheet.left,
            sheetRight: sheet.right,
            sheetTop: sheet.top,
            sheetBottom: sheet.bottom,
            saveHeight: save.height,
            touchTargets: actions.map((rect) => ({ width: rect.width, height: rect.height })),
            viewportWidth: window.innerWidth,
            viewportHeight: window.innerHeight,
            bodyOverflow: document.documentElement.scrollWidth > window.innerWidth + 1
          };
        })()
      JS

      assert_operator geometry["sheetLeft"], :>=, -1
      assert_operator geometry["sheetRight"], :<=, geometry["viewportWidth"] + 1
      assert_operator geometry["sheetTop"], :>=, -1
      assert_operator geometry["sheetBottom"], :<=, geometry["viewportHeight"] + 6
      assert_operator geometry["saveHeight"], :>=, 48
      assert geometry["touchTargets"].all? { |rect| rect["width"] >= 44 && rect["height"] >= 44 }, geometry["touchTargets"].inspect
      assert_not geometry["bodyOverflow"]
    end

    def assert_answer_history_geometry!(empty: false)
      geometry = page.evaluate_script(<<~JS)
        (() => {
          const history = document.querySelector(".profile-answer-history").getBoundingClientRect()
          const back = document.querySelector(".profile-answer-back").getBoundingClientRect()
          const card = document.querySelector("#{empty ? ".profile-answer-empty" : ".profile-answer-session"}").getBoundingClientRect()
          const rows = [...document.querySelectorAll(".profile-answer-row")]
          const copy = [...document.querySelectorAll(".profile-answer-row h3, .profile-answer-row dd")]
          const actions = [...document.querySelectorAll(".profile-answer-history a, .profile-answer-history button")]
          return {
            historyLeft: history.left,
            historyRight: history.right,
            cardLeft: card.left,
            cardRight: card.right,
            backHeight: back.height,
            rowWidths: rows.map((row) => {
              const rect = row.getBoundingClientRect()
              return { left: rect.left, right: rect.right }
            }),
            copyFits: copy.every((element) => element.scrollWidth <= element.clientWidth + 1),
            touchTargets: actions.map((element) => {
              const rect = element.getBoundingClientRect()
              return { width: rect.width, height: rect.height }
            }),
            viewportWidth: window.innerWidth,
            bodyOverflow: document.documentElement.scrollWidth > window.innerWidth + 1
          }
        })()
      JS

      assert_operator geometry["historyLeft"], :>=, -1
      assert_operator geometry["historyRight"], :<=, geometry["viewportWidth"] + 1
      assert_operator geometry["cardLeft"], :>=, -1
      assert_operator geometry["cardRight"], :<=, geometry["viewportWidth"] + 1
      assert_operator geometry["backHeight"], :>=, 44
      assert geometry["rowWidths"].all? { |row| row["left"] >= -1 && row["right"] <= geometry["viewportWidth"] + 1 }, geometry["rowWidths"].inspect
      assert geometry["copyFits"]
      assert geometry["touchTargets"].all? { |target| target["width"] >= 44 && target["height"] >= 44 }, geometry["touchTargets"].inspect
      assert_not geometry["bodyOverflow"]
    end

    def assert_no_horizontal_overflow!
      assert_not page.evaluate_script("document.documentElement.scrollWidth > window.innerWidth + 1")
    end

    def assert_long_copy_wraps!
      fits = page.evaluate_script(<<~JS)
        (() => [...document.querySelectorAll(".profile-dashboard-heading h2, .profile-field-row strong, .profile-destination-card strong")]
          .every((element) => element.scrollWidth <= element.clientWidth + 1))()
      JS
      assert fits
    end

    def emulate_profile_media(motion:, transparency:)
      page.driver.browser.execute_cdp(
        "Emulation.setEmulatedMedia",
        media: "screen",
        features: [
          { name: "prefers-reduced-motion", value: motion },
          { name: "prefers-reduced-transparency", value: transparency }
        ]
      )
    end

    def problem_browser_logs
      page.driver.browser.logs.get(:browser).select { |entry| %w[SEVERE WARNING].include?(entry.level) }
    end

    def settle_profile_motion(milliseconds: 550)
      page.driver.browser.execute_async_script("window.setTimeout(arguments[0], #{milliseconds})")
    end

    def shot(name)
      FileUtils.mkdir_p(SHOT_DIR)
      path = SHOT_DIR.join("#{name}.png")
      page.save_screenshot(path)
      warn "street-profile-shot #{path}"
    end
end
