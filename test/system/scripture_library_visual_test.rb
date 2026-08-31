require "application_system_test_case"

class ScriptureLibraryVisualTest < ApplicationSystemTestCase
  VIEWPORTS = [ [ 390, 844 ], [ 768, 1024 ], [ 1440, 900 ] ].freeze
  PANEL_ROWS = {
    "weekly" => "weekly",
    "bookmarks" => "bookmarks",
    "collection" => "collection",
    "annual" => "annual"
  }.freeze

  setup do
    Scriptures::Read.fetcher = ->(*) { file_fixture("scripture_1_sam_16.json").read }
  end

  teardown do
    Scriptures::Read.fetcher = nil
  end

  test "one daily editorial and its stream fill every production viewport" do
    FileUtils.mkdir_p(screenshot_directory) if capture_screenshots?

    VIEWPORTS.each do |width, height|
      set_system_viewport(width, height)
      visit scripture_library_path(preview: 1, locale: :fr)

      assert_selector ".scripture-library-daily h1", text: "Ils ont refusé de chanter."
      assert_selector ".scripture-library-daily[data-daily-discovery-id='preview-ps137-suspended-harps']"
      assert_selector ".scripture-library-action--hero", count: 1
      assert_selector ".scripture-library-row", count: 4
      assert_selector ".scripture-library-rama__thought", count: 2
      assert_selector ".navigation-dock__item.is-active, .desktop-navigation a.is-active", text: /Bibliothèque/i

      geometry = page.evaluate_script(<<~JS)
        (() => {
          const rect = (selector) => {
            const box = document.querySelector(selector).getBoundingClientRect();
            return { width: box.width, height: box.height, top: box.top, left: box.left };
          };
          const visible = (node) => {
            const style = getComputedStyle(node);
            const box = node.getBoundingClientRect();
            return !node.hidden && style.display !== 'none' && style.visibility !== 'hidden' && box.width > 0 && box.height > 0;
          };
          return {
            viewport: { width: innerWidth, height: innerHeight },
            world: rect('.scripture-library-daily__world'),
            hero: rect('.scripture-library-daily'),
            objectFit: getComputedStyle(document.querySelector('.scripture-library-daily__world img')).objectFit,
            currentSrc: document.querySelector('.scripture-library-daily__world img').currentSrc,
            overflow: document.documentElement.scrollWidth - document.documentElement.clientWidth,
            targets: [...document.querySelectorAll('.scripture-library-action, .scripture-library-daily summary, .scripture-library-resume__link, .scripture-library-row, .scripture-library-quiz__link, .scripture-library-rama__reply')]
              .filter(visible)
              .map((node) => {
                const box = node.getBoundingClientRect();
                return { name: node.id || node.className, width: box.width, height: box.height };
              })
          };
        })()
      JS

      assert_in_delta geometry.dig("viewport", "width"), geometry.dig("world", "width"), 1, geometry.inspect
      assert_in_delta geometry.dig("viewport", "height"), geometry.dig("world", "height"), 1, geometry.inspect
      assert_operator geometry.dig("hero", "height"), :>=, height - 2, geometry.inspect
      assert_equal "cover", geometry.fetch("objectFit")
      assert_match(%r{ps137/suspended-harps}, geometry.fetch("currentSrc"))
      assert_operator geometry.fetch("overflow"), :<=, 1, geometry.inspect
      assert geometry.fetch("targets").all? { |target| target.fetch("width").round >= 44 && target.fetch("height").round >= 44 }, geometry.inspect
      assert_empty severe_browser_logs

      save_screenshot screenshot_directory.join("library-#{width}x#{height}.png") if capture_screenshots?

      find(".scripture-library-row[data-library-row='weekly']").click
      assert_selector "#selection[data-selection-key='weekly']", wait: 5
      assert_selector "#selection:focus", wait: 5
      assert_selector "#selection .scripture-library-selection__feature", count: 1
      assert_selector "#selection .scripture-library-selection__expedition", count: 1
      panel_geometry = page.evaluate_script(<<~JS)
        (() => {
          const visible = (node) => {
            const style = getComputedStyle(node);
            const box = node.getBoundingClientRect();
            return !node.hidden && style.display !== 'none' && style.visibility !== 'hidden' && box.width > 0 && box.height > 0;
          };
          return {
            overflow: document.documentElement.scrollWidth - document.documentElement.clientWidth,
            activeElement: document.activeElement.id,
            targets: [...document.querySelectorAll('#selection a, #selection button')]
              .filter(visible)
              .map((node) => {
                const box = node.getBoundingClientRect();
                return { name: node.textContent.trim(), width: box.width, height: box.height };
              })
          };
        })()
      JS
      assert_equal "selection", panel_geometry.fetch("activeElement")
      assert_operator panel_geometry.fetch("overflow"), :<=, 1, panel_geometry.inspect
      assert panel_geometry.fetch("targets").all? { |target| target.fetch("width").round >= 44 && target.fetch("height").round >= 44 }, panel_geometry.inspect
      assert_empty severe_browser_logs
      save_screenshot screenshot_directory.join("library-weekly-#{width}x#{height}.png") if capture_screenshots?
    end
  end

  test "every recovery tool reaches its chooser and editorial actions reach the reader" do
    PANEL_ROWS.each do |row, selection|
      visit scripture_library_path(preview: 1, locale: :fr)
      find(".scripture-library-row[data-library-row='#{row}']").click

      assert_selector "#selection[data-selection-key='#{selection}']", wait: 5
      assert_selector "#selection .scripture-library-selection__item", minimum: 1
      assert_selector "#selection:focus", wait: 5
      assert_no_selector ".scripture-library-row[href='/bibliotheque']"
      assert_selector ".scripture-library-row[href*='locale=fr']", count: 4
      assert_no_selector ".scripture-library-row[data-library-row='rama']"
    end

    [ ".scripture-library-action--hero", ".scripture-library-resume__link", ".scripture-library-quiz__link" ].each do |selector|
      visit scripture_library_path(preview: 1, locale: :fr)
      find(selector).click

      assert_current_path %r{\A/escrituras/}
      assert_selector ".scripture-reader-room", wait: 8
    end

    visit scripture_library_path(preview: 1, locale: :fr)
    assert_selector ".scripture-library-rama__thought", count: 2
    assert_selector ".scripture-library-rama__reply", count: 2
    assert_empty severe_browser_logs
  end

  test "a selection can be closed with its return control or Escape without leaving the library" do
    visit scripture_library_path(preview: 1, locale: :fr)
    find(".scripture-library-row[data-library-row='weekly']").click

    assert_selector "#selection[data-selection-key='weekly']"
    assert_selector "#selection [data-library-selection-close]", text: "Revenir aux choix"
    find("#selection [data-library-selection-close]").click
    assert_no_selector "#selection"
    assert_selector "#cette-semaine:focus"
    assert_current_path scripture_library_path(preview: 1, locale: :fr)

    find("#cette-semaine").click
    assert_selector "#selection[data-selection-key='weekly']:focus"
    find("#selection").send_keys(:escape)
    assert_no_selector "#selection"
    assert_selector "#cette-semaine:focus"
    assert_empty severe_browser_logs
  end

  test "show more appends later bookmarks without taking the first twelve away" do
    person = people(:pili)
    25.times do |index|
      person.scripture_marks.create!(
        reference: "ot/1-sam/16", locale: "fr", anchor_scope: "passage", visual_style: "none",
        start_verse: (index % 23) + 1, start_offset: 0, end_verse: (index % 23) + 1, end_offset: 8,
        selected_text: "Passage sauvegardé #{index + 1}", bookmarked_at: Time.current - index.minutes
      )
    end
    sign_in_fixture_person_direct!(person)

    visit scripture_library_path(locale: :fr)
    find(".scripture-library-row[data-library-row='bookmarks']").click
    assert_selector "#selection[data-selection-key='bookmarks']"
    assert_selector "#scripture-library-selection-items > li[role=listitem] > a.scripture-library-selection__item.is-reader", count: 12
    first_title = find("#scripture-library-selection-items > li:first-child a").text

    find("#selection [data-library-search-target~='more']").click
    assert_selector "#scripture-library-selection-items > li[role=listitem] > a.scripture-library-selection__item.is-reader", count: 24
    assert_text first_title
    assert_selector "#selection [data-library-search-target~='more']"

    find("#selection [data-library-search-target~='more']").click
    assert_selector "#scripture-library-selection-items > li[role=listitem] > a.scripture-library-selection__item.is-reader", count: 25
    assert_no_selector "#selection [data-library-search-target~='more']"
    assert_selector "#selection .scripture-library-selection__status", text: "Les passages suivants ont été ajoutés."
    assert_empty severe_browser_logs
  end

  test "search keeps books inline and sends chapters directly to the reader with the keyboard" do
    visit scripture_library_path(preview: 1, locale: :fr)
    find(".scripture-library-search-drawer > summary").click

    fill_in "Rechercher dans les Écritures", with: "Psaumes"
    assert_selector "#scripture-library-suggestions [role=option]", count: 1, wait: 4
    find("#scripture_library_query").send_keys(:arrow_down)
    assert_selector "#scripture-library-suggestions [role=option][aria-selected=true]", count: 1
    find("#scripture_library_query").send_keys(:enter)
    assert_selector "#selection[data-selection-key='collection']", wait: 5
    assert_selector "#selection a.is-reader[href^='/escrituras/ot/ps/'][href*='locale=fr']", minimum: 1
    assert_equal "selection", page.evaluate_script("document.activeElement.id")

    visit scripture_library_path(preview: 1, locale: :fr)
    find(".scripture-library-search-drawer > summary").click
    fill_in "Rechercher dans les Écritures", with: "Jean 3:16"
    assert_selector "#scripture-library-suggestions [role=option]", count: 1, wait: 4
    find("#scripture_library_query").send_keys(:arrow_down, :enter)
    assert_current_path %r{\A/escrituras/nt/john/3}
    assert_selector ".scripture-reader-room[data-scripture-reference='nt/john/3']", wait: 8
    assert_empty severe_browser_logs
  end

  test "a failed Turbo request leaves the library ready and explains what to do" do
    visit scripture_library_path(preview: 1, locale: :fr)
    find(".scripture-library-search-drawer > summary").click
    assert_selector "#recherche-ecritures[data-library-search-target='form']"
    assert page.evaluate_async_script(<<~JS), "the connected search controller must receive Turbo failures"
      const done = arguments[0]
      const element = document.querySelector("[data-controller~='library-search']")
      const deadline = performance.now() + 5_000
      const waitForController = () => {
        const controller = window.Stimulus?.getControllerForElementAndIdentifier(element, "library-search")
        if (controller) return done(true)
        if (performance.now() >= deadline) return done(false)
        requestAnimationFrame(waitForController)
      }
      waitForController()
    JS
    page.execute_script(<<~JS)
      const form = document.querySelector('#recherche-ecritures');
      const row = document.querySelector(".scripture-library-row[data-library-row='weekly']");
      const frame = document.querySelector('turbo-frame#library_selection');
      form.classList.add('is-loading');
      form.setAttribute('aria-busy', 'true');
      form.querySelectorAll('button, input').forEach((control) => { control.disabled = true; });
      row.classList.add('is-loading');
      row.setAttribute('aria-busy', 'true');
      frame.setAttribute('aria-busy', 'true');
      frame.dispatchEvent(new CustomEvent('turbo:fetch-request-error', {
        bubbles: true,
        detail: { request: { url: window.location.href } }
      }));
    JS

    assert_selector "#recherche-ecritures[aria-busy='false']"
    assert_no_selector "#recherche-ecritures.is-loading"
    assert_no_selector ".scripture-library-row.is-loading"
    assert_nil page.evaluate_script("document.querySelector('turbo-frame#library_selection').getAttribute('aria-busy')")
    assert_selector "#scripture-library-search-status.is-error", text: "La recherche n’a pas abouti. Vérifie ta connexion puis réessaie."
    assert_selector "#scripture-library-suggestions[hidden]", visible: :all
    assert page.evaluate_script("[...document.querySelectorAll('#recherche-ecritures button, #recherche-ecritures input')].every((control) => !control.disabled)")
    assert_empty severe_browser_logs
  end

  test "the standalone reader traps keyboard focus" do
    visit scripture_path("ot/ps/49", cite: "Psaume 49:17", locale: :fr)

    assert_selector ".scripture-reader-room", wait: 8
    page.execute_script(<<~JS)
      const close = document.querySelector("[data-scripture-close]");
      close.focus();
      window.dispatchEvent(new KeyboardEvent("keydown", {
        key: "Tab", shiftKey: true, bubbles: true, cancelable: true
      }));
    JS
    assert page.evaluate_script("document.activeElement.closest('.scripture-veil') !== null"), "focus must remain in the reader dialog"
    assert_empty severe_browser_logs
  end

  test "server deep links restore focus and reduced motion removes meaningful travel" do
    page.driver.browser.execute_cdp(
      "Emulation.setEmulatedMedia",
      media: "screen",
      features: [ { name: "prefers-reduced-motion", value: "reduce" } ]
    )
    visit scripture_library_path(
      preview: 1, locale: :fr, section: "canon", collection: "old_testament",
      book: "ot/ps", anchor: "selection"
    )

    assert_selector ".scripture-library-row[data-library-row='collection'][aria-current='true']"
    assert_selector "#selection[data-selection-key='collection']:focus"
    motion = page.evaluate_script(<<~JS)
      (() => {
        const row = getComputedStyle(document.querySelector('.scripture-library-row'));
        const selection = getComputedStyle(document.querySelector('#selection'));
        return {
          rowTransform: row.transform,
          rowTransition: parseFloat(row.transitionDuration) || 0,
          selectionAnimation: parseFloat(selection.animationDuration) || 0
        };
      })()
    JS
    assert_includes [ "none", "matrix(1, 0, 0, 1, 0, 0)" ], motion.fetch("rowTransform")
    assert_operator motion.fetch("rowTransition"), :<=, 0.001, motion.inspect
    assert_operator motion.fetch("selectionAnimation"), :<=, 0.001, motion.inspect
  ensure
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", media: "screen", features: [])
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
      visit root_path
    end

    def capture_screenshots?
      ENV["LIBRARY_SCREENSHOTS"] == "1"
    end

    def screenshot_directory
      Rails.root.join("tmp/street-shots/scripture-library")
    end

    def severe_browser_logs
      page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
    rescue NoMethodError
      []
    end
end
