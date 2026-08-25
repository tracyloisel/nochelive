require "test_helper"

class WardAddsControllerTest < ActionDispatch::IntegrationTest
  test "how-to page explains the night and points at Benidorm" do
    get add_ward_path
    assert_response :success
    assert_select "h1", text: I18n.t("ward.add_title")
    assert_select "p.lede", text: I18n.t("ward.add_lede")
    assert_select "p.lede", text: I18n.t("ward.add_run")
    assert_select "p.lede", text: /líder de la obra misional/
    assert_select "p.lede", text: /Rama Benidorm/
    assert_select "p.lede", text: /fork/
    assert_select "a.quiet-link[href=?]", "https://github.com/tracyloisel/nochelive"
    assert_select ".btn.btn-gold", count: 1
    assert_select ".btn.btn-gold", text: /Rama Benidorm/
    assert_select "a.btn.btn-gold[href=?]", ward_profile_path("RAMA")
    assert_select "form[action=?]", wards_path, count: 0
    assert_select ".story-ticks", count: 0
    assert_select ".play-sheet-grip", count: 0
    assert_select "input[name=name]", count: 0
  end

  test "nosotros is the same how-to page" do
    get about_path
    assert_response :success
    assert_select "h1", text: I18n.t("ward.add_title")
  end
end
