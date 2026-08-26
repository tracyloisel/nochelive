require "test_helper"

class NightsControllerTest < ActionDispatch::IntegrationTest
  test "noches is the paper night feed" do
    get nights_path
    assert_response :success
    assert_select "body.is-paper-hall"
    assert_select "h1", text: "Noche Live"
    assert_select ".home-paper"
    assert_select ".street-hub-lockup-star"
    assert_select ".street-hub-kicker", text: I18n.t("home.nights")
    assert_select "#street_quiz", count: 0
    assert_select ".play-reel", count: 0
    assert_select ".home-doors a.btn.btn-gold[href=?]", church_path, text: I18n.t("church.invite")
    assert_select ".home-doors a[href=?]", search_path, count: 0
    assert_select ".home-doors a[href=?]", about_path, count: 0
    assert_select ".chrome-drawer a.home-menu-row[href=?]", nights_path
    assert_select ".chrome-drawer .place-input", count: 0
    assert_select ".home-upcoming .night-hit", text: /Reyes y Profetas/
    assert_select ".home-upcoming .night-hit", text: /Rama Benidorm/
    assert_select ".home-past .night-hit", count: 1
    assert_select ".home-paper .night-still .night-poster"
    assert_select ".btn.btn-gold", count: 1
    assert_select ".story-ticks", count: 0
    assert_select ".play-sheet-grip", count: 0
    assert_select ".chrome-drawer .mute"
    assert_select ".chrome-tools", count: 0
    assert_select ".chrome-drawer .lang-switch.is-drawer"
    assert_select ".chrome-drawer .lang-opt .picto-flag-es"
  end
end
