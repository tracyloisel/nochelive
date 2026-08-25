require "application_system_test_case"

class HomeSmokeTest < ApplicationSystemTestCase
  test "home is a street quiz and nights live in the hamburger" do
    visit root_path
    assert_selector "#street_quiz.play-reel.is-quiz.is-street"
    assert_no_selector ".home-paper"
    assert_no_selector ".story-ticks"
    assert_no_selector ".play-sheet-grip"
    assert_selector ".choice-btn"
    assert_selector ".street-score span", text: "0"
    assert_no_selector ".btn.btn-gold"
    assert_selector "details.home-menu"
    assert_selector ".chrome-tools .mute + .lang-switch"

    first(".choice-btn").click
    assert_selector ".quiz-board.is-settled"
    assert_selector ".play-sheet[data-sheet-snap=open]"
    assert_selector ".street-score"
    assert_text I18n.t("quiz.read_more")
    assert_selector "a.quiet-link", text: I18n.t("quiz.read_more")
    assert_selector "a.quiet-link .quiz-cite"
    assert_selector ".quiz-cite", count: 1
    assert_button I18n.t("quiz.next")

    find(".home-menu-btn").click
    find("details.home-menu").click_link I18n.t("home.nights")
    assert_current_path nights_path
    assert_selector ".home-paper"
    assert_text "Reyes y Profetas"
    assert_no_selector "#street_quiz"
    assert_no_selector ".place-input"

    visit root_path
    find(".lang-switch > summary").click
    click_button "Français"
    assert_selector "html[lang=fr]"
    assert_selector ".lang-switch > summary .picto-flag-fr"
  end
end
