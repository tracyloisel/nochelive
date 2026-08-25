require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "home and health" do
    get root_path
    assert_response :success
    get "/up"
    assert_response :success
  end

  test "home is a paper feed of nights" do
    get root_path
    assert_response :success
    assert_select "h1", text: "Noche Live"
    assert_select ".home-paper"
    assert_select ".play-reel", count: 0
    assert_select ".home-doors a[href=?]", about_path, text: I18n.t("home.who")
    assert_select ".home-doors a[href=?]", search_path, text: I18n.t("home.search_page")
    assert_select "details.home-menu:not([open])"
    assert_select "details.home-menu a[href=?]", search_path
    assert_select "details.home-menu a[href=?]", about_path
    assert_select "details.home-menu .place-input", count: 0
    assert_select ".home-paper .place-input", count: 0
    assert_select ".home-upcoming .night-hit", text: /Reyes y Profetas/
    assert_select ".home-upcoming .night-hit", text: /Rama Benidorm/
    assert_select ".home-past .night-hit", count: 1
    assert_select ".ward-grid", count: 0
    assert_select ".btn.btn-gold", count: 0
    assert_select ".story-ticks", count: 0
    assert_select ".play-sheet-grip", count: 0
  end

  test "remembered rama does not steal the home feed" do
    sign_in_congregation
    get root_path
    assert_response :success
    assert_select ".home-paper"
    assert_select "h1", text: "Noche Live"
  end
end
