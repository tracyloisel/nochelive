require "application_system_test_case"

class HomeSmokeTest < ApplicationSystemTestCase
  test "home is the world hub and the drawer keeps secondary actions" do
    visit root_path
    assert_selector "#street_world"
    assert_no_selector ".home-paper"
    assert_no_selector ".story-ticks"
    assert_selector "nav.home-menu"
    assert_selector ".home-menu-btn .picto-menu"
    assert_selector ".quiz-hud-who"
    assert_no_selector ".chrome-tools"

    find(".home-menu-btn").click
    assert_selector "dialog.chrome-drawer[open] .home-menu-nav-hub"
    assert_equal "chrome_drawer_title", page.evaluate_script("document.activeElement.id")
    assert_selector ".home-menu-invite", text: I18n.t("hub_menu.invite_friend")
    assert_selector ".home-menu-invite[href='#{street_challenges_path(anchor: "inviter")}']"
    assert_selector ".home-menu-row[href='#{street_leaderboard_path}']", text: I18n.t("hub_menu.leaderboard")
    assert_selector ".home-menu-row[href='#{scripture_library_path}']", text: I18n.t("scripture_library.title")
    assert_selector ".home-menu-kicker", text: /#{Regexp.escape(I18n.t("hub_menu.space"))}/i
    assert_selector ".home-menu-kicker", text: /#{Regexp.escape(I18n.t("hub_menu.settings"))}/i
    assert_selector ".hub-menu-legal a", count: 3
    find(".chrome-drawer .lang-switch.is-drawer > summary").click
    click_button "Français"
    assert_selector "html[lang=fr]"
    find(".home-menu-btn").click unless page.has_css?("dialog.chrome-drawer[open]")
    find(".chrome-drawer .lang-switch.is-drawer > summary").click unless page.has_css?(".chrome-drawer details.lang-switch.is-drawer[open]")
    assert_selector "dialog.chrome-drawer[open] .lang-opt.is-on .picto-flag-fr"
    find(".chrome-drawer").send_keys(:escape)
    assert_no_selector "dialog.chrome-drawer[open]"
    assert_equal "true", page.evaluate_script("document.activeElement.matches('.home-menu-btn')").to_s
  end
end
