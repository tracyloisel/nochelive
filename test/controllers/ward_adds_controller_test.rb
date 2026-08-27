require "test_helper"

class WardAddsControllerTest < ActionDispatch::IntegrationTest
  test "nosotros tells Tracy's gift and names the private initiative" do
    get add_ward_path
    assert_response :success
    assert_select "body.is-church-journey.is-about-journey"
    assert_select "#ward_add.about-journey"
    assert_select ".about-journey-hero[style*=?]", "/media/about/community-origin-v1.png"
    assert_select ".about-journey-intro h1", text: I18n.t("about.title")
    assert_select ".about-journey-act", count: 3
    assert_select ".about-face img[src=?]", "/media/about/tracy.png"
    assert_select ".about-face img[alt=?]", I18n.t("about.portrait_alt")
    assert_select ".about-face strong", text: "Tracy Loisel"
    assert_select ".about-face span", text: I18n.t("about.role")
    assert_select "h1", text: I18n.t("about.title")
    assert_select "p.lede", text: I18n.t("about.gift")
    assert_select "p.lede", text: I18n.t("about.born")
    assert_select "p.lede", text: I18n.t("about.source")
    assert_select "p.lede", text: I18n.t("about.purse")
    assert_select "p.lede", text: I18n.t("about.association")
    assert_select ".about-journey-disclaimer", text: I18n.t("about.disclaimer")
    assert_select "p.lede", text: /líder de la obra misional/
    assert_select "p.lede", text: /Rama de Benidorm/
    assert_select ".about-journey-disclaimer", text: /Iglesia de Jesucristo de los Santos de los Últimos Días/
    assert_select ".about-journey-disclaimer", text: /iniciativa totalmente privada/
    assert_select "p.lede", text: /Pull Request/
    assert_select ".about-journey-maker"
    assert_select ".about-journey-maker nav.about-reach"
    assert_select "a.about-reach-chip[href=?]", "https://wa.me/34689226754"
    assert_select "a.about-reach-chip[href=?]", "https://www.instagram.com/tracy_loisel/"
    assert_select ".about-reach-chip strong", text: "+34 689 22 67 54"
    assert_select ".about-reach-chip strong", text: "@tracy_loisel"
    assert_select "a.about-github[href=?]", "https://github.com/tracyloisel/nochelive"
    assert_select "a.quiet-link[href=?]", platform_stats_path
    assert_select ".btn.btn-gold.about-github", count: 1
    assert_select "a[href=?]", ward_profile_path("RAMA"), count: 0
    assert_select "form[action=?]", wards_path, count: 0
    assert_select ".story-ticks", count: 0
    assert_select ".play-sheet-grip", count: 0
    assert_select ".play-reel", count: 0
    assert_select "p.skip", count: 0
    assert_select "input[name=name]", count: 0
  end

  test "nosotros is the same gift page" do
    get about_path
    assert_response :success
    assert_select "h1", text: I18n.t("about.title")
    assert_select ".about-face img[src=?]", "/media/about/tracy.png"
    get "/media/about/tracy.png"
    assert_response :success
    assert_match %r{image/png}, response.media_type
  end
end
