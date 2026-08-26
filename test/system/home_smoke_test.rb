require "application_system_test_case"

class HomeSmokeTest < ApplicationSystemTestCase
  test "home is the world hub and nights live in the hamburger" do
    visit root_path
    assert_selector "#street_world"
    assert_no_selector ".home-paper"
    assert_no_selector ".story-ticks"
    assert_selector "details.home-menu"
    assert_selector ".home-menu-btn .picto-gear"
    assert_selector ".chrome-tools .mute + .lang-switch"

    find(".home-menu-btn").click
    assert_selector "details.home-menu[open] .home-menu-nav"
    assert_selector ".home-menu-row", text: I18n.t("street.history_menu")
    assert_selector ".home-menu-kicker", text: /noche de hogar/i
    find("details.home-menu").click_link I18n.t("home.nights")
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
    find(".lang-switch > summary").click
    click_button "Français"
    assert_selector "html[lang=fr]"
    assert_selector ".lang-switch > summary .picto-flag-fr"
  end
end
