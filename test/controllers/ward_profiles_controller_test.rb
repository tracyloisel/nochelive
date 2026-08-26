require "test_helper"

class WardProfilesControllerTest < ActionDispatch::IntegrationTest
  test "public profile shows the Benidorm chapel pin and one gold live door" do
    get ward_profile_path("RAMA")
    assert_response :success
    assert_select "h1", text: "Rama Benidorm"
    assert_select "a.rama-pin[href*='Alfonso']"
    assert_select "a.rama-pin[href*='Benidorm']"
    assert_select "body.is-paper-hall"
    assert_select "#rama_profile.hall-paper"
    assert_select ".hall-sheet", count: 0
    assert_select ".hall-still"
    assert_select "a.rama-pin[href*='google.com/maps']"
    assert_select ".btn.btn-gold", text: /Entrar/
    assert_select ".btn.btn-gold", count: 1
    assert_select "a.quiet-link", text: /Solo ver/
    assert_select ".btn.btn-gold", text: /Solo ver/, count: 0
    assert_select "nav.home-menu"
    assert_select ".chrome-drawer a[href=?]", root_path
    assert_select ".chrome-drawer a[href=?]", about_path
    assert_select ".chrome-drawer a[href=?]", search_path
    assert_select ".rama-cta a", text: /Otra rama/, count: 0
    assert_select ".btn.btn-gold", text: /Abrir la noche/, count: 0
    assert_select ".play-reel", count: 0
    assert_select ".gate", count: 0
    assert_select "p.skip", count: 0
    assert_select ".rama-grid", count: 0
    assert_select "ul.rama-nights"
    assert_select "a.rama-night", count: 3
    assert_select "a.rama-night[href=?]", night_name_path("DAVID")
    assert_select "a.rama-night[href=?]", ward_memory_path("RAMA", "QUIT")
    assert_select ".rama-night-date", text: I18n.l(game_sessions(:cerrada).starts_at.to_date)
    assert_select ".rama-night-missionaries", text: /Élder Soto/
    assert_select ".rama-night-missionaries", text: /Hermana Clark/
    assert_select ".rama-night-role", text: I18n.t("presenter.missionaries")
  end

  test "host without a live night gets Abrir la noche as the gold CTA" do
    sign_in_ward(wards(:blank), token: "rama-blank")
    get ward_profile_path("BLANK")
    assert_response :success
    assert_select ".btn.btn-gold", text: /Abrir la noche/
    assert_select ".btn.btn-gold", count: 1
    assert_select ".btn.btn-gold", text: /Entrar/, count: 0
  end

  test "congregation cookie does not open fichas" do
    sign_in_congregation
    get ward_fichas_path
    assert_redirected_to ward_profile_path("RAMA")
  end
end
