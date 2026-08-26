require "application_system_test_case"

class HomeSmokeTest < ApplicationSystemTestCase
  test "home is the world hub and nights live in the hamburger" do
    visit root_path
    assert_selector "#street_world"
    assert_no_selector ".home-paper"
    assert_no_selector ".story-ticks"
    assert_selector "nav.home-menu"
    assert_selector ".home-menu-btn .picto-menu"
    assert_selector ".chrome-face"
    assert_no_selector ".chrome-tools"

    find(".home-menu-btn").click
    assert_selector "dialog.chrome-drawer[open] .home-menu-nav"
    assert_selector ".home-menu-row", text: I18n.t("street.history_menu")
    assert_selector ".home-menu-row", text: I18n.t("street.menu_play")
    assert_selector ".home-menu-kicker", text: /#{Regexp.escape(I18n.t("home.ward_menu"))}/i
    assert_selector ".home-menu-kicker", text: /iglesia de jesucristo/i
    assert_no_selector ".home-menu-kicker", text: /noche de hogar/i
    click_link I18n.t("home.nights_menu")
    assert_current_path nights_path
    assert_selector "body.is-paper-hall"
    assert_selector ".home-paper"
    assert_selector ".street-hub-lockup-star"
    assert_selector ".street-hub-kicker", text: /#{Regexp.escape(I18n.t("home.nights"))}/i
    assert_text "Reyes y Profetas"
    assert_no_selector "#street_quiz"
    assert_no_selector ".place-input"
    find(".home-past .night-hit").click
    assert_current_path ward_memory_path("RAMA", "QUIT")
    assert_no_selector ".story-ticks"
    assert_no_selector ".btn-gold"

    visit root_path
    find(".home-menu-btn").click
    assert_selector "dialog.chrome-drawer[open]"
    find(".chrome-drawer .lang-switch.is-drawer > summary").click
    click_button "Français"
    assert_selector "html[lang=fr]"
    find(".home-menu-btn").click
    assert_selector ".chrome-drawer .lang-opt.is-on .picto-flag-fr"
  end
end
