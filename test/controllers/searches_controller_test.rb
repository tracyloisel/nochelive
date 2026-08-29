require "test_helper"

class SearchesControllerTest < ActionDispatch::IntegrationTest
  test "empty search does not dump listed ramas" do
    8.times { |i| extra_ward(i, listed: true) }

    get search_path
    assert_response :success
    assert_select "h1", text: I18n.t("home.menu_search")
    assert_select "body.is-paper-hall.is-rama-search"
    assert_select ".home-paper.rama-search-scene"
    assert_select ".rama-search-sheet"
    assert_select "link[href*='pages/search']"
    assert_select ".rama-search-sigil"
    assert_select ".rama-search-kicker", text: I18n.t("home.search_page")
    assert_select ".play-reel", count: 0
    assert_select ".ward-picker-query[placeholder=?]", I18n.t("street.gate_search_ph")
    assert_not_includes response.body, "Benidorm, tu pueblo"
    assert_select ".ward-picker-wait", text: I18n.t("home.search_wait")
    assert_select "form.ward-picker-search[data-ward-search-location-unavailable-value=?]", I18n.t("home.search_location_unavailable")
    assert_select "input[name=lat]"
    assert_select "input[name=lng]"
    assert_select "button.ward-picker-locate", text: I18n.t("street.gate_locate")
    assert_select ".chrome-drawer a[href=?]", search_path
    assert_select ".ward-hit", count: 0
    assert_select ".ward-hit.is-featured", count: 0
    assert_select ".ward-hit", text: /Rama Extra/, count: 0
  end

  test "nearby coords launch a search without a text query" do
    Wards::QueryLocator.forced_near = [
      Wards::QueryLocator.attrs_from(JSON.parse(file_fixture("maps_ward_madrid.json").read).first)
    ]

    get search_path, params: { lat: "40.42", lng: "-3.70" }
    assert_response :success
    assert_select ".ward-picker-stake", text: I18n.t("street.gate_nearby")
    assert_select ".home-search-lede"
    assert_select ".ward-hit", count: 1
    assert_select ".ward-hit.is-featured", text: /Madrid 1st Ward/
    assert_select ".ward-pick-address", text: /Calle del Prado 1/
    assert_select ".ward-pick-form.is-featured .ward-pick-star"
    assert_select ".ward-hit.is-featured .ward-pick-star", count: 0
    assert_select ".ward-hit.is-featured .ward-pick-enter"
  end

  test "query filters listed unidades only" do
    get search_path, params: { q: "Benidorm" }
    assert_response :success
    assert_select ".ward-picker-wait", text: I18n.t("home.search_wait")
    assert_select ".ward-hit", text: /Rama Benidorm/
    assert_select ".ward-pick-address", text: /Alfonso Puchades/
    assert_select ".ward-pick-form.is-featured .ward-pick-star"
    assert_select ".ward-hit.is-featured .ward-pick-star", count: 0
    assert_select ".ward-hit", text: /Rama vacía/, count: 0

    get search_path, params: { q: "Alicante" }
    assert_select ".ward-hit", text: /Rama Benidorm/

    get search_path, params: { q: "Madrid" }
    assert_select ".ward-hit", count: 0
    assert_select ".ward-picker-missing", text: /#{Regexp.escape(I18n.t("home.empty"))}/

    get search_path, params: { q: "zzz" }
    assert_select ".ward-hit", count: 0
    assert_select ".ward-picker-missing", text: /#{Regexp.escape(I18n.t("home.empty"))}/
    assert_select ".ward-picker-missing h2", text: I18n.t("street.gate_missing_title")
    assert_select "a.btn-navy[href=?]", "https://maps.churchofjesuschrist.org/"
    assert_select "a.quiet-link[href=?]", root_path, text: I18n.t("street.gate_continue_without_ward")

    get search_path, params: { q: "RAMA" }
    assert_select ".ward-hit", text: /Rama Benidorm/

    get search_path, params: { q: "BLANK" }
    assert_select ".ward-hit", count: 0
  end

  test "locator hits render a church unit pick not a code" do
    Wards::QueryLocator.forced_hits = [
      Wards::QueryLocator.attrs_from(JSON.parse(file_fixture("maps_ward_madrid.json").read).first)
    ]

    get search_path, params: { q: "Madrid" }
    assert_response :success
    assert_select ".ward-hit", text: /Madrid 1st Ward/
    assert_select ".ward-pick-address", text: /Calle del Prado 1/
    assert_select "input[name=church_unit_id][value='999001']"
    assert_select "form.ward-pick-form input[name=code]", count: 0
  end

  test "cambiar search posts to street rama pick and keeps the flag" do
    extra_ward(9, listed: true)

    get search_path(cambiar: 1, q: "Extra")
    assert_response :success
    assert_select "h1", text: I18n.t("street.change_ward")
    assert_select ".home-search-lede", text: I18n.t("street.change_ward_lede")
    assert_select "input[name=cambiar][value='1']"
    assert_select "form.ward-pick-form[action=?]", street_ward_pick_path
    assert_select "form.ward-pick-form[data-turbo-frame=?]", "_top"
    assert_select "form.ward-pick-form[action=?]", enter_ward_path, count: 0
  end

  test "turbo frame returns picker results only" do
    get search_path, headers: { "Turbo-Frame" => "ward_picker_results" }
    assert_response :success
    assert_select "turbo-frame#ward_picker_results"
    assert_select "h1", count: 0
  end
end
