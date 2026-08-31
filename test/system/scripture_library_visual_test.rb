require "application_system_test_case"

class ScriptureLibraryVisualTest < ApplicationSystemTestCase
  VIEWPORTS = [ [ 390, 844 ], [ 768, 1024 ], [ 1440, 900 ] ].freeze

  test "the library keeps one clear intention per line at production viewports" do
    FileUtils.mkdir_p(screenshot_directory) if capture_screenshots?

    VIEWPORTS.each do |width, height|
      set_system_viewport(width, height)
      visit scripture_library_path(preview: 1, locale: :fr)

      assert_selector ".scripture-library__hero h1", text: "Bibliothèque"
      assert_selector ".scripture-library-row", count: 7
      assert_selector ".scripture-library-row.is-priority", count: 1
      assert_selector ".navigation-dock__item.is-active", text: /Bibliothèque/i
      assert_operator page.evaluate_script("document.querySelector('.scripture-library-row').getBoundingClientRect().height"), :>=, 44
      assert_empty severe_browser_logs

      save_screenshot screenshot_directory.join("library-#{width}x#{height}.png") if capture_screenshots?
    end
  end

  private

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
