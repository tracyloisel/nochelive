require "application_system_test_case"
require "base64"

class WardProfileVisualTest < ApplicationSystemTestCase
  VIEWPORTS = [ [ 390, 844 ], [ 768, 1024 ], [ 1440, 900 ] ].freeze
  SCREENSHOT_DIRECTORY = Rails.root.join("tmp/street-shots/rama-profile")
  PRIVATE_QUESTION = "¿Por qué parece tan larga la espera cuando ya no quedan fuerzas?"
  PRIVATE_REFLECTION = "Nunca había visto a Melquisedec aquí; ahora quiero volver a leerlo."

  setup do
    @ward = wards(:demo)
    @ward.update!(scripture_circle_mode: "active")
    @viewer = people(:pili)
    @week = create_current_week!
  end

  test "member with two real Circle conversations receives the complete story at every viewport" do
    first, second = publish_weekly_conversations!
    sign_in_fixture_person_direct!(@viewer)
    install_locale_cookie!("es")

    each_viewport("member-circle") do |width, height|
      assert_narrative_contract!(circle: true)
      assert_selector ".rama-circle .rama-conversation", count: 2
      assert_selector ".rama-conversation", text: first.body
      assert_selector ".rama-conversation", text: second.body
      assert_selector ".rama-conversation__reply", text: /1 respuesta/
      assert_selector ".rama-circle__privacy"
      assert_selector ".rama-player.is-you", text: @viewer.given_name
      assert_selector ".rama-league__foot", text: /Tú eres #/
      assert_visual_contract!(width:, height:)
      capture_full_page_screenshot("member-circle", width:, height:)
    end
  end

  test "member with an empty Circle receives a humane empty state at every viewport" do
    sign_in_fixture_person_direct!(@viewer)
    install_locale_cookie!("es")

    each_viewport("member-empty") do |width, height|
      assert_narrative_contract!(circle: true)
      assert_selector ".rama-circle .rama-circle-empty", count: 1
      assert_selector ".rama-circle-empty h3", text: /Aún no hay conversaciones esta semana/
      assert_selector ".rama-circle-empty a[href='#{scripture_library_path}']"
      assert_no_selector ".rama-circle .rama-conversation", visible: :all
      assert_no_selector ".rama-circle__privacy", visible: :all
      assert_visual_contract!(width:, height:)
      capture_full_page_screenshot("member-empty", width:, height:)
    end
  end

  test "guest never receives Circle markup or private conversation content at any viewport" do
    private_author = @ward.people.create!(
      given_name: "Inés",
      family_name: "Privada",
      avatar_key: Player::AVATARS.first,
      favorite_year: 1998,
      locale: "es"
    )
    publish_circle_root!(person: private_author, reference: "ot/ps/102", kind: "question", body: PRIVATE_QUESTION)
    clear_browser_identity!
    install_locale_cookie!("es")

    each_viewport("guest") do |width, height|
      assert_narrative_contract!(circle: false)
      assert_no_selector ".rama-circle", visible: :all
      refute_includes page.html, PRIVATE_QUESTION
      refute_includes page.html, private_author.display_name
      assert_no_selector ".rama-player.is-you", visible: :all
      assert_no_selector ".rama-league__foot p", visible: :all
      assert_visual_contract!(width:, height:)
      capture_full_page_screenshot("guest", width:, height:)
    end
  end

  private

    def each_viewport(scenario)
      VIEWPORTS.each do |width, height|
        set_system_viewport(width, height)
        visit ward_profile_path(@ward.code)
        wait_for_rama_paint!

        yield width, height
      rescue Minitest::Assertion => error
        raise Minitest::Assertion, "#{scenario} at #{width}x#{height}: #{error.message}"
      end
    end

    def assert_narrative_contract!(circle:)
      expected = %w[rama-story-hero rama-week rama-story-night]
      expected << "rama-circle" if circle
      expected.concat(%w[rama-league rama-story-visit])
      chapter_classes = page.evaluate_script(<<~JS)
        Array.from(document.querySelectorAll('#rama_profile > section')).map(function(section) {
          return Array.from(section.classList).find(function(name) {
            return ['rama-story-hero', 'rama-week', 'rama-story-night', 'rama-circle', 'rama-league', 'rama-story-visit'].includes(name);
          });
        });
      JS

      assert_equal expected, chapter_classes
      assert_selector "body.is-rama-profile"
      assert_selector "#rama_profile.rama-page[data-controller~='rama-motion']"
      assert_selector ".rama-story-hero h1", count: 1
      assert_selector ".rama-story-hero__actions a", count: 3
      assert_selector ".rama-week .rama-story-action", count: 1
      assert_selector ".rama-story-night .rama-story-action", count: 1
      assert_selector ".rama-league"
      assert_selector ".rama-story-visit .rama-visit-actions a", count: 3

      # These are the exact shared components. They remain siblings of the
      # page surface so the Rama composition cannot fork or restyle the HUD.
      assert_selector "nav.home-menu.is-hud[data-hud-theme='celestial-dark']", visible: :all
      assert_selector "header.quiz-hud[data-hud-theme='celestial-dark']", visible: :all
      assert_selector "nav.navigation-dock", visible: :all
      assert_selector "nav.navigation-dock .navigation-dock__item.is-active[aria-current='page']", visible: :all
      assert_no_selector "#rama_profile nav.home-menu, #rama_profile header.quiz-hud, #rama_profile nav.navigation-dock", visible: :all

      assert_no_selector ".rama-countdown, [data-controller~='hub-countdown'], [data-countdown-target]", visible: :all
      assert_no_selector ".rama-next-players, .rama-stats, .rama-events, .rama-live-carousel, .rama-card", visible: :all
      refute_match(/00:00:00|0\s+(?:people|personas?|personnes?)\s+(?:expected|esperadas?|attendues?)/i, page.html)
    end

    def assert_visual_contract!(width:, height:)
      assert_shared_chrome_does_not_cover_hero_actions!
      reveal_all_chapters!
      wait_for_all_rama_images!
      assert_links_are_uncovered!

      geometry = page.evaluate_script(<<~JS)
        (function() {
          var visible = function(element) {
            var style = getComputedStyle(element);
            var box = element.getBoundingClientRect();
            return !element.hidden && style.display !== 'none' && style.visibility !== 'hidden' && box.width > 0 && box.height > 0;
          };
          var chapters = Array.from(document.querySelectorAll('#rama_profile > .rama-chapter'));
          var links = Array.from(document.querySelectorAll('#rama_profile a[href]')).filter(visible).map(function(link) {
            var box = link.getBoundingClientRect();
            return {
              label: link.textContent.trim().replace(/\s+/g, ' '),
              href: link.getAttribute('href'),
              width: box.width,
              height: box.height,
              pointerEvents: getComputedStyle(link).pointerEvents
            };
          });
          var copy = Array.from(document.querySelectorAll(
            '.rama-story-hero__copy, .rama-editorial-copy, .rama-reading-sheet, .rama-league__head, .rama-league__foot, .rama-visit-sheet'
          )).filter(visible);

          return {
            viewport: { width: innerWidth, height: innerHeight },
            documentWidth: document.documentElement.scrollWidth,
            chapterBoxes: chapters.map(function(chapter) {
              var box = chapter.getBoundingClientRect();
              return { className: chapter.className, top: box.top + scrollY, left: box.left, right: box.right, width: box.width, height: box.height };
            }),
            motionStates: chapters.map(function(chapter) { return chapter.dataset.ramaMotionState; }),
            links: links,
            contentBoxes: copy.map(function(element) {
              var box = element.getBoundingClientRect();
              return { className: element.className, left: box.left, right: box.right, width: box.width };
            }),
            copyOverflows: copy.filter(function(element) {
              return element.scrollWidth > element.clientWidth + 3;
            }).map(function(element) { return element.className; }),
            images: Array.from(document.querySelectorAll('.rama-chapter-art img')).map(function(image) {
              return { src: image.currentSrc || image.src, complete: image.complete, width: image.naturalWidth, height: image.naturalHeight };
            })
          };
        })();
      JS

      assert_equal width, geometry.dig("viewport", "width"), geometry.inspect
      assert_equal height, geometry.dig("viewport", "height"), geometry.inspect
      assert_operator geometry.fetch("documentWidth"), :<=, width + 1, geometry.inspect
      assert geometry.fetch("chapterBoxes").all? { |box| box.fetch("left") >= -1 && box.fetch("right") <= width + 1 }, geometry.inspect
      assert geometry.fetch("chapterBoxes").all? { |box| box.fetch("width") >= width - 1 && box.fetch("height") >= 500 }, geometry.inspect
      assert_equal geometry.fetch("chapterBoxes").map { |box| box.fetch("top") }.sort,
        geometry.fetch("chapterBoxes").map { |box| box.fetch("top") }, geometry.inspect
      assert geometry.fetch("motionStates").all? { |state| state == "ready" }, geometry.inspect
      assert geometry.fetch("contentBoxes").all? { |box| box.fetch("left") >= -1 && box.fetch("right") <= width + 1 }, geometry.inspect
      assert_empty geometry.fetch("copyOverflows"), geometry.inspect
      assert geometry.fetch("images").all? { |image| image.fetch("complete") && image.fetch("width").positive? && image.fetch("height").positive? }, geometry.inspect
      assert geometry.fetch("links").all? { |link| link.fetch("href").present? && link.fetch("pointerEvents") != "none" }, geometry.inspect
      assert geometry.fetch("links").all? { |link| link.fetch("width").round >= 44 && link.fetch("height").round >= 44 }, geometry.inspect
      assert_empty severe_browser_logs
    end

    def assert_shared_chrome_does_not_cover_hero_actions!
      clearance = page.evaluate_script(<<~JS)
        (function() {
          var dock = document.querySelector('nav.navigation-dock');
          var action = document.querySelector('.rama-story-hero__actions a:last-child');
          if (!dock || !action || getComputedStyle(dock).display === 'none') return { applicable: false };
          var dockBox = dock.getBoundingClientRect();
          var actionBox = action.getBoundingClientRect();
          var horizontalOverlap = Math.min(dockBox.right, actionBox.right) - Math.max(dockBox.left, actionBox.left);
          var verticalOverlap = Math.min(dockBox.bottom, actionBox.bottom) - Math.max(dockBox.top, actionBox.top);
          return {
            applicable: true,
            overlap: horizontalOverlap > 0 && verticalOverlap > 0,
            dockTop: dockBox.top,
            actionBottom: actionBox.bottom
          };
        })();
      JS

      assert_not clearance.fetch("overlap"), clearance.inspect if clearance.fetch("applicable")
    end

    def assert_links_are_uncovered!
      all("#rama_profile a[href]", visible: true).each do |link|
        page.execute_script("arguments[0].scrollIntoView({ block: 'center', inline: 'nearest', behavior: 'instant' })", link)
        hit = page.evaluate_script(<<~JS, link)
          (function(link) {
            var box = link.getBoundingClientRect();
            var x = Math.max(0, Math.min(innerWidth - 1, box.left + box.width / 2));
            var y = Math.max(0, Math.min(innerHeight - 1, box.top + box.height / 2));
            var target = document.elementFromPoint(x, y);
            return {
              clickable: Boolean(target && (target === link || link.contains(target))),
              label: link.textContent.trim().replace(/\s+/g, ' '),
              target: target && (target.id || target.className || target.tagName),
              point: { x: x, y: y },
              box: { left: box.left, top: box.top, right: box.right, bottom: box.bottom }
            };
          })(arguments[0]);
        JS
        assert hit.fetch("clickable"), hit.inspect
      end
      page.execute_script(<<~JS)
        document.querySelectorAll('#rama_profile > .rama-chapter').forEach(function(chapter) { chapter.scrollLeft = 0; });
        window.scrollTo({ top: 0, left: 0, behavior: 'instant' });
      JS
    end

    def create_current_week!
      program = StudyProgram.create!(
        slug: "rama-visual-#{SecureRandom.hex(6)}",
        title: "Ven, sígueme #{Date.current.year}",
        year: Date.current.year + 20,
        canon: "old_testament",
        locale: "es",
        status: "published",
        source_url: "https://example.test/rama-visual"
      )
      program.study_units.create!(
        slug: "semana-salmos-102-110",
        kind: "week",
        position: 1,
        title: "Esta semana: Salmos 102 y 110",
        source_url: "https://example.test/rama-visual/semana",
        starts_on: Date.current.beginning_of_week,
        ends_on: Date.current.end_of_week,
        scripture_refs: %w[ot/ps/102 ot/ps/110],
        status: "published"
      )
    end

    def publish_weekly_conversations!
      question = publish_circle_root!(
        person: people(:carmen_garcia),
        reference: "ot/ps/102",
        kind: "question",
        body: PRIVATE_QUESTION
      )
      reflection = publish_circle_root!(
        person: people(:carmen_lopez),
        reference: "ot/ps/110",
        kind: "reflection",
        body: PRIVATE_REFLECTION
      )
      question.scripture_circle_thread.scripture_circle_posts.create!(
        ward: @ward,
        person: @viewer,
        parent: question,
        conversation_root: question,
        kind: "reply",
        locale: "es",
        body: "Yo también me lo pregunto."
      )
      [ question, reflection ]
    end

    def publish_circle_root!(person:, reference:, kind:, body:)
      thread = @ward.scripture_circle_threads.find_or_create_by!(reference:)
      thread.scripture_circle_posts.create!(
        ward: @ward,
        person:,
        kind:,
        locale: "es",
        body:
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

    def clear_browser_identity!
      page.driver.browser.manage.delete_all_cookies
      visit "/favicon-32.png"
    end

    def install_locale_cookie!(locale)
      page.driver.browser.manage.add_cookie(name: Locale::COOKIE.to_s, value: locale, path: "/")
    end

    def wait_for_rama_paint!
      assert_selector ".rama-story-hero[data-rama-motion-state='ready']", wait: 8
      painted = page.driver.browser.execute_async_script(<<~JS)
        var done = arguments[0];
        var ready = document.fonts && document.fonts.ready ? document.fonts.ready : Promise.resolve();
        var timeout = new Promise(function(resolve) { window.setTimeout(resolve, 2500); });
        Promise.race([ready, timeout]).then(function() {
          requestAnimationFrame(function() { requestAnimationFrame(function() { done(true); }); });
        });
      JS
      assert painted, "Rama assertions must wait until fonts and the first motion frame have painted"
    end

    def reveal_all_chapters!
      all("#rama_profile > .rama-chapter", visible: :all).each_with_index do |chapter, index|
        page.execute_script("arguments[0].scrollIntoView({ block: 'center', behavior: 'instant' })", chapter)
        assert_selector "#rama_profile > .rama-chapter:nth-of-type(#{index + 1})[data-rama-motion-state='ready']", wait: 8
      end
      page.execute_script("window.scrollTo({ top: 0, behavior: 'instant' })")
      assert page.evaluate_script("Array.from(document.querySelectorAll('#rama_profile > .rama-chapter')).every(function(chapter) { return chapter.dataset.ramaMotionState === 'ready'; })")
    end

    def wait_for_all_rama_images!
      loaded = page.driver.browser.execute_async_script(<<~JS)
        var done = arguments[0];
        var images = Array.from(document.querySelectorAll('.rama-chapter-art img'));
        var waits = images.map(function(image) {
          if (image.complete) return Promise.resolve();
          return new Promise(function(resolve) {
            image.addEventListener('load', resolve, { once: true });
            image.addEventListener('error', resolve, { once: true });
          });
        });
        var timeout = new Promise(function(resolve) { window.setTimeout(resolve, 5000); });
        Promise.race([Promise.all(waits), timeout]).then(function() { done(true); });
      JS
      assert loaded
    end

    def capture_full_page_screenshot(scenario, width:, height:)
      return unless ENV["RAMA_SCREENSHOTS"] == "1"

      FileUtils.mkdir_p(SCREENSHOT_DIRECTORY)
      page.execute_script("window.scrollTo({ top: 0, behavior: 'instant' })")
      metrics = page.driver.browser.execute_cdp("Page.getLayoutMetrics")
      content = metrics["cssContentSize"] || metrics.fetch("contentSize")
      result = page.driver.browser.execute_cdp(
        "Page.captureScreenshot",
        format: "png",
        fromSurface: true,
        captureBeyondViewport: true,
        clip: {
          x: 0,
          y: 0,
          width: content.fetch("width"),
          height: content.fetch("height"),
          scale: 1
        }
      )
      File.binwrite(
        SCREENSHOT_DIRECTORY.join("#{scenario}-#{width}x#{height}.png"),
        Base64.decode64(result.fetch("data"))
      )
    rescue Selenium::WebDriver::Error::WebDriverError
      save_screenshot SCREENSHOT_DIRECTORY.join("#{scenario}-#{width}x#{height}.png")
    end

    def severe_browser_logs
      page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
        .reject { |entry| entry.message.include?("/favicon.ico") && entry.message.include?("404") }
    rescue NoMethodError
      []
    end
end
