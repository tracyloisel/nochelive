require "application_system_test_case"

class StreetMapExpeditionsVisualTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/street-shots/map-expeditions")
  PACK_IDS = %w[exp_psalms_disappearing_voice exp_psalms_nameless_king].freeze

  test "the complete journey stays reachable while expeditions become a swipeable collection" do
    emulate_motion_preference("no-preference")
    active = create_expedition_week!(
      slug: "active-#{SecureRandom.hex(5)}",
      title: "La voix qui demeure",
      starts_on: Date.current,
      ends_on: Date.current + 6.days
    )
    upcoming = create_expedition_week!(
      slug: "upcoming-#{SecureRandom.hex(5)}",
      title: "Les portes de demain",
      starts_on: Date.current + 2.days,
      ends_on: Date.current + 4.days
    )

    [ [ 390, 844 ], [ 768, 1024 ], [ 1440, 900 ] ].each do |width, height|
      set_system_viewport(width, height)
      visit street_map_path
      wait_for_map_entry

      assert_selector ".mapa-mode-tab.is-active[href='#{street_map_path(view: "journey")}']"
      assert_selector ".mapa-node", count: QuizDefinition.catalog.pack_ids.size, visible: :all
      assert_no_selector ".mapa-expedition-hero"
      assert_no_horizontal_layout_overflow
      shot("journey-#{width}x#{height}")
    end

    set_system_viewport(390, 844)
    visit street_map_path(view: "expeditions", expedition: upcoming.id)
    wait_for_map_entry

    assert_selector ".mapa-expedition-carousel[role='list']"
    assert_selector ".mapa-expedition-card", count: 2
    assert_selector ".mapa-expedition-card.is-active .mapa-expedition-card__link[aria-current='page']", count: 1
    assert_selector ".mapa-expedition-card__schedule", text: /#{Regexp.escape(I18n.t("street.expeditions.starts_on", date: I18n.l(upcoming.starts_on)))}/
    assert_selector ".mapa-expedition-journey-link[href='#{street_map_path(view: "journey")}']"
    assert_selector ".mapa-expedition-hero__cta"
    assert_map_motion_contract!
    assert_selector ".mapa-expedition-door", count: PACK_IDS.size
    assert_no_horizontal_layout_overflow

    before = page.evaluate_script("document.querySelector('#mapa-expedition-carousel').scrollLeft")
    before_dot = page.evaluate_script("Array.from(document.querySelectorAll('.mapa-expedition-carousel-dots i')).findIndex((dot) => dot.classList.contains('is-active'))")
    find("button[data-direction='1']").click
    page.driver.browser.execute_async_script("window.setTimeout(arguments[0], 800)")
    after = page.evaluate_script("document.querySelector('#mapa-expedition-carousel').scrollLeft")
    after_dot = page.evaluate_script("Array.from(document.querySelectorAll('.mapa-expedition-carousel-dots i')).findIndex((dot) => dot.classList.contains('is-active'))")
    assert_operator after, :>, before
    assert_operator after_dot, :>, before_dot
    assert_no_horizontal_layout_overflow
    shot("expeditions-390x844")

    visit street_map_path(view: "expeditions", expedition: active.id)
    wait_for_map_entry
    assert_selector ".mapa-expedition-card.is-active .mapa-expedition-card__link[aria-current='page']"
    assert_selector ".mapa-expedition-card__schedule", text: /\d/
    assert_no_horizontal_layout_overflow
    shot("expedition-active-390x844")

    page.execute_script("document.querySelector('.mapa-expedition-hero')?.scrollIntoView({ block: 'center' })")
    page.driver.browser.execute_async_script("window.setTimeout(arguments[0], 250)")
    assert_selector ".mapa-expedition-hero h2"
    assert_selector ".mapa-expedition-door", count: PACK_IDS.size
    assert_no_horizontal_layout_overflow
    shot("expedition-detail-390x844")

    [ [ 768, 1024 ], [ 1440, 900 ] ].each do |width, height|
      set_system_viewport(width, height)
      visit street_map_path(view: "expeditions", expedition: active.id)
      wait_for_map_entry
      assert_selector ".mapa-expedition-carousel[role='list']"
      assert_selector ".mapa-expedition-card", count: 2
      assert_selector ".mapa-expedition-card.is-active .mapa-expedition-card__link[aria-current='page']", count: 1
      assert_selector ".mapa-expedition-hero__cta"
      assert_selector ".mapa-expedition-door", count: PACK_IDS.size
      assert_no_horizontal_layout_overflow
      shot("expedition-active-#{width}x#{height}")
    end

    emulate_reduced_motion do
      visit street_map_path(view: "expeditions", expedition: active.id)
      wait_for_map_entry
      assert_equal "none", page.evaluate_script("getComputedStyle(document.querySelector('.mapa-expeditions-heading')).animationName")
      assert_equal "1", page.evaluate_script("getComputedStyle(document.querySelector('.mapa-expeditions-heading')).opacity")
      assert_no_horizontal_layout_overflow
    end
    assert_empty page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
  end

  private

    def wait_for_map_entry
      assert_selector ".street-map-page.is-ready"
      page.driver.browser.execute_async_script("window.setTimeout(arguments[0], 750)")
    end

    def assert_map_motion_contract!
      assert_equal "mapa-heading-in", page.evaluate_script("getComputedStyle(document.querySelector('.mapa-heading')).animationName")
      assert_equal "mapa-motion-rise", page.evaluate_script("getComputedStyle(document.querySelector('.mapa-expedition-carousel-shell')).animationName")
      assert_selector ".mapa-expedition-hero[style*='street-expedition-hero']"
    end

    def emulate_motion_preference(value)
      page.driver.browser.execute_cdp(
        "Emulation.setEmulatedMedia",
        media: "screen",
        features: [ { name: "prefers-reduced-motion", value: } ]
      )
    end

    def emulate_reduced_motion
      emulate_motion_preference("reduce")
      yield
    ensure
      page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [])
    end

    def create_expedition_week!(slug:, title:, starts_on:, ends_on:)
      program = StudyProgram.create!(
        slug: "program-#{slug}",
        title: "Programme #{title}",
        year: [ StudyProgram.maximum(:year).to_i + 1, Date.current.year + 1 ].max,
        canon: "old_testament",
        locale: "fr",
        status: "published",
        source_url: "https://example.test/#{slug}"
      )
      unit = program.study_units.create!(
        slug: "week-#{slug}",
        kind: "week",
        position: 1,
        title: title,
        source_url: "https://example.test/#{slug}/week",
        starts_on:,
        ends_on:,
        scripture_refs: [ "Psaumes" ],
        status: "published"
      )
      content = {
        "questions" => [],
        "readings" => [],
        "expedition" => {
          "id" => slug,
          "title" => { "fr" => title },
          "subtitle" => { "fr" => "Deux portes cachées" },
          "promise" => { "fr" => "Entre dans une histoire qui t’attend." },
          "artwork" => "/media/expeditions/psalms-2026/home-key-art-v1.png",
          "pack_ids" => PACK_IDS,
          "packs" => PACK_IDS.map.with_index do |pack_id, index|
            { "id" => pack_id, "title" => { "fr" => "Porte #{index + 1}" }, "hook" => { "fr" => "Une histoire à ouvrir." } }
          end
        }
      }
      unit.study_quiz_versions.create!(
        version: 1,
        status: "published",
        editorial_locale: "fr",
        content:,
        content_digest: Digest::SHA256.hexdigest(content.to_json),
        published_at: Time.current
      )
      unit
    end

    def assert_no_horizontal_layout_overflow
      overflow = page.evaluate_script("document.documentElement.scrollWidth - window.innerWidth")
      assert_operator overflow, :<=, 1, "document overflowed horizontally by #{overflow}px"
    end

    def shot(name)
      FileUtils.mkdir_p(SHOT_DIR)
      page.save_screenshot(SHOT_DIR.join("#{name}.png"))
    end
end
