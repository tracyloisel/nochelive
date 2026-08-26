require "test_helper"

class SearchesControllerTest < ActionDispatch::IntegrationTest
  test "empty search still shows Benidorm and hides unlisted unidades" do
    8.times { |i| extra_ward(i) }

    get search_path
    assert_response :success
    assert_select "h1", text: I18n.t("home.menu_search")
    assert_select "body.is-paper-hall"
    assert_select ".home-paper"
    assert_select ".street-hub-lockup-star"
    assert_select ".street-hub-kicker", text: I18n.t("home.search_page")
    assert_select ".play-reel", count: 0
    assert_select ".place-input"
    assert_select "details.home-menu a[href=?]", search_path
    assert_select ".ward-hit", text: /Rama Benidorm/
    assert_select ".ward-hit", text: /Rama vacía/, count: 0
    assert_select ".ward-hit", text: /Rama Extra/, count: 0
    assert_select ".ward-hit", count: 1
    assert_select ".home-paper .night-still .night-poster"
  end

  test "listed extras still cap at six" do
    8.times { |i| extra_ward(i, listed: true) }

    get search_path
    assert_response :success
    assert_select ".ward-hit", text: /Rama Benidorm/
    assert_select ".ward-hit", maximum: 6
  end

  test "query filters listed unidades only" do
    get search_path, params: { q: "Benidorm" }
    assert_response :success
    assert_select ".ward-hit", text: /Rama Benidorm/
    assert_select ".ward-hit", text: /Rama vacía/, count: 0

    get search_path, params: { q: "Alicante" }
    assert_select ".ward-hit", text: /Rama Benidorm/

    get search_path, params: { q: "Madrid" }
    assert_select ".ward-hit", count: 0
    assert_select "p.lede.home-empty", text: /No encontramos/

    get search_path, params: { q: "zzz" }
    assert_select ".ward-hit", count: 0
    assert_select "p.lede.home-empty", text: /No encontramos/

    get search_path, params: { q: "RAMA" }
    assert_select ".ward-hit", text: /Rama Benidorm/

    get search_path, params: { q: "BLANK" }
    assert_select ".ward-hit", count: 0
  end
end
