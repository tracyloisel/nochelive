require "application_system_test_case"

class LoadingIndicatorTest < ApplicationSystemTestCase
  SHOT_DIR = Rails.root.join("tmp/street-shots/loading-remediation")

  test "predictive link prefetch stays invisible across hub themes and viewports" do
    catalog = Array(YAML.safe_load_file(Hubs::Backdrop::CATALOG)["backdrops"])
    worlds = {
      "light" => catalog.find { |row| row.dig("theme", "mode") == "light" },
      "dark" => catalog.find { |row| row.dig("theme", "mode") == "dark" }
    }

    worlds.each do |theme, world|
      Hubs::Backdrop.entries = [ world ]
      [ [ 390, 844 ], [ 768, 1024 ], [ 1440, 900 ] ].each do |width, height|
        set_system_viewport(width, height)
        visit root_path

        assert_selector "#street_world[data-hub-theme='#{theme}']"
        assert_selector ".noche-loading[hidden]", visible: :all
        all(".navigation-dock__item", minimum: 2)[1].hover
        sleep 0.5

        assert_selector "html[data-loading-state='idle']", visible: :all
        assert_selector ".noche-loading[hidden]", visible: :all
        assert_equal false, page.evaluate_script("document.documentElement.scrollWidth > window.innerWidth")
        shot("hub-#{theme}-#{width}x#{height}")
        assert_empty page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
      end
    end
  ensure
    Hubs::Backdrop.reset!
  end

  test "a foreground request still shows and resolves the loading indicator" do
    visit root_path

    page.execute_script(<<~JS)
      document.dispatchEvent(new CustomEvent("turbo:before-fetch-request", {
        bubbles: true,
        detail: { fetchOptions: { headers: { Accept: "text/html" } } }
      }))
    JS
    assert_selector ".noche-loading:not([hidden])", visible: :all
    assert_includes %w[visible slow], page.evaluate_script("document.documentElement.dataset.loadingState")
    shot("foreground-loading-390x844")

    page.execute_script("document.dispatchEvent(new CustomEvent('turbo:render', { bubbles: true }))")
    assert_selector "html[data-loading-state='idle']", visible: :all
    assert_selector ".noche-loading[hidden]", visible: :all
  end

  test "offline and failed states never leave a loading spinner behind" do
    visit root_path

    page.execute_script("window.dispatchEvent(new Event('offline'))")
    assert_selector "html[data-loading-state='offline']", visible: :all
    assert_selector ".noche-loading[hidden]", visible: :all

    page.execute_script(<<~JS)
      document.dispatchEvent(new CustomEvent("turbo:fetch-request-error", {
        bubbles: true,
        detail: { request: { headers: { Accept: "text/html" } } }
      }))
    JS
    assert_selector "html[data-loading-state='failed']", visible: :all
    assert_selector ".noche-loading[hidden]", visible: :all

    page.execute_script("window.dispatchEvent(new Event('online'))")
    assert_selector "html[data-loading-state='idle']", visible: :all
  end

  test "the Scripture loading threshold is intentional on phone tablet and desktop" do
    [ [ 390, 844 ], [ 768, 1024 ], [ 1440, 900 ] ].each do |width, height|
      set_system_viewport(width, height)
      visit root_path

      page.execute_script(<<~JS)
        document.documentElement.classList.add("is-scripture-open")
        const loader = document.getElementById("scripture_loading")
        loader.hidden = false
        loader.dataset.state = "slow"
        loader.setAttribute("aria-hidden", "false")
        loader.querySelector("[data-reader-loading-chapter]").textContent = "Salmo 52"
        loader.querySelectorAll("[data-reader-loading-template]").forEach((node) => {
          node.textContent = node.dataset.readerLoadingTemplate.replace("__CHAPTER__", "Salmo 52")
        })
      JS

      assert_selector "#scripture_loading[data-state='slow']:not([hidden])"
      assert_selector ".reader-loading-copy.is-slow", visible: true
      assert_selector ".reader-loading-chapter", text: "Salmo 52", visible: true
      assert_selector ".reader-loading-dismiss", visible: true
      assert_selector ".noche-loading[hidden]", visible: :all
      assert_equal false, page.evaluate_script("document.documentElement.scrollWidth > window.innerWidth")
      sleep 0.25
      shot("scripture-slow-#{width}x#{height}")
      assert_empty page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
    end

    page.execute_script("document.getElementById('scripture_loading').dataset.state = 'failed'")
    assert_selector ".reader-loading-copy.is-failed", visible: true
    assert_selector ".reader-loading-retry", visible: true
    sleep 0.25
    shot("scripture-failed-1440x900")
  end

  private

    def shot(name)
      FileUtils.mkdir_p(SHOT_DIR)
      page.save_screenshot(SHOT_DIR.join("#{name}.png"))
    end
end
