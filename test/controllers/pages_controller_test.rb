require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "church hub is a paper hall with four illustrated doors" do
    get church_path
    assert_response :success
    assert_select "body.is-paper-hall"
    assert_select ".home-paper"
    assert_select "h1", text: "Noche Live"
    assert_select "a.street-hub-lockup-wordmark[href=?]", root_path
    assert_select ".street-hub-kicker", text: I18n.t("church.kicker")
    assert_select "p.lede.paper-lede", text: I18n.t("church.lede")
    assert_select "a.paper-door[href=?]", church_meet_path
    assert_select "a.paper-door[href=?]", church_beliefs_path
    assert_select "a.paper-door[href=?]", church_missionaries_path
    assert_select "a.paper-door[href=?]", church_worship_path
    assert_select ".paper-door-hint", text: I18n.t("church.beliefs_hint")
    assert_select "a.paper-door[href=?] img[src=?]", church_beliefs_path, "/media/church/beliefs.jpg"
    assert_select ".btn.btn-gold", count: 0
    assert_select ".story-ticks", count: 0
    assert_select ".chrome-drawer a.home-menu-row[href=?]", church_path
  end

  test "meet missionaries keeps the title with the still" do
    get church_meet_path
    assert_response :success
    assert_select ".paper-story .hall-still img[src=?]", "/media/church/meet.jpg"
    assert_select ".paper-story h2.paper-page-title", text: I18n.t("church.meet_title")
    assert_select "section.home-paper > h2.paper-page-title", count: 0
    assert_select "a.btn.btn-gold[href=?]", PagesController::VISIT_URL
    assert_select "a.btn.btn-gold[href*='gclid']", count: 0
    assert_select "p.lede", text: I18n.t("church.meet_expect")
    assert_select ".paper-other-doors a.btn.btn-navy", count: 3
    assert_select ".paper-other-doors a.btn.btn-navy[href=?]", church_beliefs_path
    assert_select "a", text: I18n.t("church.back"), count: 0
  end

  test "beliefs page carries Come Unto Christ topics and a local visit door" do
    get church_beliefs_path
    assert_response :success
    assert_select ".paper-story h2.paper-page-title", text: I18n.t("church.beliefs_title")
    assert_select "section.home-paper > h2.paper-page-title", count: 0
    assert_select ".belief-beat h3", text: I18n.t("church.belief.christ_title")
    assert_select ".belief-beat h3", text: I18n.t("church.belief.word_title")
    assert_select ".belief-q", count: 5
    assert_select ".belief-q summary", text: I18n.t("church.belief.faq.denomination.q")
    assert_select "a.btn.btn-gold[href=?]", church_meet_path
    assert_select "a.quiet-link[href=?]", PagesController::BELIEVE_URL
    assert_select "a[href*='gclid']", count: 0
    assert_select ".paper-other-doors a.btn.btn-navy", count: 3
    assert_select "a", text: I18n.t("church.back"), count: 0
    assert_select ".story-ticks", count: 0
  end

  test "missionaries keeps the title with the still" do
    get church_missionaries_path
    assert_response :success
    assert_select ".paper-story .hall-still img[src=?]", "/media/church/missionaries.jpg"
    assert_select ".paper-story h2.paper-page-title", text: I18n.t("church.missionaries_title")
    assert_select "section.home-paper > h2.paper-page-title", count: 0
    assert_select "a.btn.btn-gold[href=?]", PagesController::VISIT_URL
    assert_select ".paper-other-doors a.btn.btn-navy", count: 3
    assert_select "a", text: I18n.t("church.back"), count: 0
  end

  test "worship keeps the title with the still and links to the map" do
    get church_worship_path
    assert_response :success
    assert_select ".paper-story .hall-still img[src=?]", "/media/church/worship.jpg"
    assert_select ".paper-story h2.paper-page-title", text: I18n.t("church.worship_title")
    assert_select "section.home-paper > h2.paper-page-title", count: 0
    assert_select "a.btn.btn-gold[href=?]", PagesController::MAPS_URL
    assert_select "p.lede", text: I18n.t("church.worship_first")
    assert_select ".paper-other-doors a.btn.btn-navy", count: 3
    assert_select "a", text: I18n.t("church.back"), count: 0
  end

  test "legal names Tracy Loisel and Render on a charter sheet" do
    get legal_path
    assert_response :success
    assert_select "body.is-paper-hall"
    assert_select "#legal_charter.is-charter"
    assert_select ".hall-sheet.charter-sheet h1", text: I18n.t("legal.title")
    assert_select ".paper-facts", text: /Tracy Loisel/
    assert_select "a[href='mailto:tracy.loisel@gmail.com']"
    assert_select ".paper-facts", text: /Render Services, Inc./
    assert_select ".paper-facts", text: /525 Brannan/
    assert_select "a.quiet-link[href=?]", privacy_path
    assert_select "a.quiet-link[href=?]", platform_stats_path
    assert_select ".story-ticks", count: 0
    assert_select ".btn.btn-gold", count: 0
  end

  test "privacy is a readable charter with cookie inventory and AEPD rights" do
    get privacy_path
    assert_response :success
    assert_select "body.is-paper-hall"
    assert_select "#privacy_charter.is-charter"
    assert_select ".hall-sheet.charter-sheet"
    assert_select "h1", text: I18n.t("privacy.title")
    assert_select ".charter-block h2", text: I18n.t("privacy.ask.title")
    assert_select ".charter-block p", text: I18n.t("privacy.ask.body")
    assert_select ".charter-block p", text: I18n.t("privacy.cookies.third_parties")
    assert_select ".charter-block p", text: I18n.t("privacy.cookies.mute")
    assert_select ".charter-cookies dt", text: "noche_device"
    assert_select ".charter-cookies dt", text: "noche_ward"
    assert_select ".charter-cookies dt", text: "noche_player, noche_client"
    assert_select "a.quiet-link[href=?]", "https://www.aepd.es", text: I18n.t("privacy.rights.aepd")
    assert_select "a[href='mailto:tracy.loisel@gmail.com']"
    assert_select "a.quiet-link[href=?]", legal_path
    assert_select ".charter-sheet .lede", count: 0
    assert_select ".story-ticks", count: 0
    assert_select ".btn.btn-gold", count: 0
  end

  test "stats is a public carta with four marble chapters" do
    get platform_stats_path
    assert_response :success
    assert_select "body.is-paper-hall"
    assert_select "#stats_charter.is-charter.is-stats"
    assert_select ".hall-sheet.charter-sheet h1", text: I18n.t("stats.title")
    assert_select "section.stats-chapter h2", count: 4
    assert_select "section.stats-chapter h2", text: I18n.t("stats.house.title")
    assert_select "section.stats-chapter h2", text: I18n.t("stats.path.title")
    assert_select "section.stats-chapter h2", text: I18n.t("stats.meet.title")
    assert_select "section.stats-chapter h2", text: I18n.t("stats.world.title")
    assert_select ".stats-tile"
    assert_select ".stats-langs"
    assert_select ".stats-share.is-path"
    assert_select "dl.paper-facts", count: 0
    assert_select ".stats-podium"
    assert_select ".stats-podium-name", text: "Carmen"
    assert_select ".stats-podium-name", text: /García/, count: 0
    assert_select ".is-stats", text: /1833/, count: 0
    assert_select ".street-liga-podium", count: 0
    assert_select ".story-ticks", count: 0
    assert_select ".btn.btn-gold", count: 0
    assert_select ".chrome-drawer a.home-menu-row[href=?]", platform_stats_path, text: I18n.t("stats.menu")
    assert_select "a.quiet-link[href=?]", about_path, text: I18n.t("home.who")
    get about_path
    assert_select "a.quiet-link[href=?]", platform_stats_path
    get legal_path
    assert_select "a.quiet-link[href=?]", platform_stats_path
  end

  test "stats shows an honest empty world when no pack is finished" do
    QuizAnswer.delete_all
    QuizRun.delete_all
    get platform_stats_path
    assert_response :success
    assert_select ".stats-empty", text: I18n.t("stats.world.empty")
    assert_select ".stats-podium", count: 0
    assert_select ".stats-board", count: 0
  end
end
