require "test_helper"

class StatsRevealSystemTest < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  test "stats page renders with all structural elements" do
    visit platform_stats_path

    assert_selector "#stats_page"
    assert_selector ".stats-header h1"
    assert_selector ".stats-header-lede"
    assert_selector ".stats-tile"
    assert_selector ".stats-langs"
    assert_selector ".stats-path-circle"
    assert_selector ".stats-path-svg circle"
    assert_selector ".stats-dock .street-hub-nav-item", count: 5
    assert_selector ".stats-about"
    assert_selector ".stats-about .stats-about-title"
  end

  test "stats page has counter data attributes in DOM" do
    visit platform_stats_path
    assert_selector "#stats_page"
    assert_selector ".stats-header"

    count = all("[data-stat-counter]").size
    assert count >= 4, "Expected at least 4 stat counters in DOM, found #{count}"

    count2 = all("[data-stat-current]").size
    assert count2 >= 4, "Expected at least 4 stat current spans in DOM, found #{count2}"
  end

  test "lang bar elements exist in DOM" do
    visit platform_stats_path

    count = all(".stats-lang-bar").size
    assert count >= 1, "Expected at least 1 lang bar in DOM, found #{count}"
  end
end