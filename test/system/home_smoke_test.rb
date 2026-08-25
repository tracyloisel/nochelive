require "application_system_test_case"

class HomeSmokeTest < ApplicationSystemTestCase
  test "home is a paper feed and search lives on its own page" do
    visit root_path
    assert_text "Noche Live"
    assert_text I18n.t("home.who")
    assert_text I18n.t("home.search_page")
    assert_text I18n.t("home.upcoming")
    assert_text "Reyes y Profetas"
    assert_no_selector ".play-reel.is-home"
    assert_selector ".home-paper"
    assert_selector "details.home-menu"
    assert_no_selector ".place-input"

    find(".home-doors").click_link I18n.t("home.search_page")
    assert_current_path search_path
    assert_selector ".place-input"
    assert_text "Rama Benidorm"
    assert_no_text "Rama vacía"

    visit root_path
    find(".home-menu-btn").click
    find("details.home-menu").click_link I18n.t("home.who")
    assert_current_path about_path
    assert_selector ".btn.btn-gold"
    assert_no_selector "form input[name=name]"
  end
end
