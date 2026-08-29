require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "church hub is a cinematic journey with four doors and a dock" do
    get church_path
    assert_response :success
    assert_select "body.is-church-journey.is-celestial-dark"
    assert_select ".church-landing[style*=?]", generated_media_src("media/church/journey/threshold-v2.png", format: "webp")
    assert_select ".church-landing h1", text: I18n.t("church.invite")
    assert_select "a.paper-door[href=?]", church_meet_path
    assert_select "a.paper-door[href=?]", church_beliefs_path
    assert_select "a.paper-door[href=?]", church_missionaries_path
    assert_select "a.paper-door[href=?]", church_worship_path
    assert_select ".paper-door-hint", text: I18n.t("church.beliefs_hint")
    assert_select ".home-menu.is-hud[data-hud-theme='celestial-dark'] .quiz-hud[data-hud-theme='celestial-dark']"
    assert_select ".navigation-dock .navigation-dock__item", count: 5
    assert_select ".navigation-dock__item.is-active[href=?]", church_path
    assert_select ".btn.btn-gold", count: 0
    assert_select ".story-ticks", count: 0
    assert_select ".chrome-drawer a.home-menu-invite[href=?]", street_challenges_path(anchor: "inviter")
    assert_select ".chrome-drawer a.home-menu-row[href=?]", study_program_path
  end

  test "meet missionaries opens as a cinematic chapter" do
    get church_meet_path
    assert_response :success
    assert_select ".church-meet[style*=?]", generated_media_src("media/church/journey/meet-v2.png", format: "webp")
    assert_select ".church-meet-hero h1", text: I18n.t("church.meet_title")
    assert_select ".church-meet-story .church-meet-card"
    assert_select "a.btn.btn-gold[href=?]", PagesController::VISIT_URL
    assert_select "a.btn.btn-gold[href*='gclid']", count: 0
    assert_select "p.lede", text: I18n.t("church.meet_expect")
    assert_select ".missionary-chapter-path.is-back[href=?]", church_worship_path
    assert_select ".missionary-chapter-home[href=?]", church_path
    assert_select ".missionary-chapter-path.is-next[href=?]", church_beliefs_path
    assert_select ".missionary-path-progress i.is-current:nth-child(1)"
    assert_select ".home-menu.is-hud .quiz-hud"
    assert_select ".navigation-dock__item.is-active[href=?]", church_path
  end

  test "beliefs page carries Come Unto Christ topics and a local visit door" do
    get church_beliefs_path
    assert_response :success
    assert_select ".church-beliefs[style*=?]", generated_media_src("media/church/journey/beliefs-v2.png", format: "webp")
    assert_select ".church-beliefs h1", text: I18n.t("church.beliefs_title")
    assert_select ".belief-beat h3", text: I18n.t("church.belief.christ_title")
    assert_select ".belief-beat h3", text: I18n.t("church.belief.word_title")
    assert_select ".belief-q", count: 5
    assert_select ".belief-q summary", text: I18n.t("church.belief.faq.denomination.q")
    assert_select "a.btn.btn-gold[href=?]", church_meet_path
    assert_select ".church-beliefs-invitation .belief-invitation-back", count: 0
    assert_select ".church-beliefs-invitation .belief-official-link", count: 0
    assert_select "a[href*='gclid']", count: 0
    assert_select ".missionary-chapter-path.is-back[href=?]", church_meet_path
    assert_select ".missionary-chapter-home[href=?]", church_path
    assert_select ".missionary-chapter-path.is-next[href=?]", church_missionaries_path
    assert_select ".missionary-path-progress i.is-current:nth-child(2)"
    assert_select ".home-menu.is-hud .quiz-hud"
    assert_select ".navigation-dock__item.is-active[href=?]", church_path
    assert_select ".story-ticks", count: 0
  end

  test "missionaries keeps the title with the still" do
    get church_missionaries_path
    assert_response :success
    assert_select ".church-scene--missionaries[style*=?]", generated_media_src("media/church/journey/missionaries-v2.png", format: "webp")
    assert_select ".church-missionaries h1", text: I18n.t("church.missionaries_title")
    assert_select ".missionary-act", count: 3
    assert_select ".missionary-gift", count: 3
    assert_select ".missionary-steps li", count: 3
    assert_select "a.btn.btn-gold[href^=?]", PagesController::MISSION_URL
    assert_select ".missionary-chapter-path.is-back[href=?]", church_beliefs_path
    assert_select ".missionary-chapter-home[href=?]", church_path
    assert_select ".missionary-chapter-path.is-next[href=?]", church_worship_path
    assert_select ".missionary-path-progress i.is-current:nth-child(3)"
    assert_select ".home-menu.is-hud .quiz-hud"
    assert_select ".navigation-dock__item.is-active[href=?]", church_path
  end

  test "worship keeps the title with the still and links to the map" do
    get church_worship_path
    assert_response :success
    assert_select ".church-scene--worship[style*=?]", generated_media_src("media/church/journey/worship-v2.png", format: "webp")
    assert_select ".church-worship h1", text: I18n.t("church.worship_title")
    assert_select ".worship-schedule li", count: 2
    assert_select ".worship-reassurances article", count: 3
    assert_select "a.btn.btn-gold[href=?]", PagesController::MAPS_URL
    assert_select ".worship-source[href^=?]", PagesController::WORSHIP_URL
    assert_select ".worship-meet-link[href=?]", church_meet_path
    assert_select ".missionary-chapter-path.is-back[href=?]", church_missionaries_path
    assert_select ".missionary-chapter-home[href=?]", church_path
    assert_select ".missionary-chapter-path.is-next[href=?]", church_meet_path
    assert_select ".missionary-path-progress i.is-current:nth-child(4)"
    assert_select ".home-menu.is-hud .quiz-hud"
    assert_select ".navigation-dock__item.is-active[href=?]", church_path
  end

  test "legal is a cinematic charter journey naming Tracy Loisel and Render" do
    get legal_path
    assert_response :success
    assert_select "body.is-church-journey.is-charter-journey.is-charter-legal"
    assert_select "body.is-paper-hall", count: 0
    assert_select "#legal_charter.charter-journey--legal"
    assert_select ".charter-journey-hero[style*=?]", generated_media_src("media/legal/legal-charter-celestial-light-v1.webp", format: "webp")
    assert_select ".charter-journey-intro h1", text: I18n.t("legal.title")
    assert_select ".charter-journey-story .charter-journey-act", count: 3
    assert_select ".paper-facts", text: /Tracy Loisel/
    assert_select "a[href='mailto:tracy.loisel@gmail.com']"
    assert_select ".paper-facts", text: /Render Services, Inc./
    assert_select ".paper-facts", text: /525 Brannan/
    assert_select ".charter-journey-foot", count: 0
    assert_select ".charter-journey-story a[href=?]", privacy_path, count: 0
    assert_select ".charter-journey-story a[href=?]", platform_stats_path, count: 0
    assert_select ".navigation-dock .navigation-dock__item", count: 5
    assert_select ".home-menu.is-hud[data-hud-theme='celestial-light'] .quiz-hud[data-hud-theme='celestial-light']"
    assert_select ".hall-sheet", count: 0
    assert_select ".story-ticks", count: 0
    assert_select ".btn.btn-gold", count: 0
  end

  test "privacy is a readable charter with cookie inventory and AEPD rights" do
    get privacy_path
    assert_response :success
    assert_select "body.is-church-journey.is-charter-journey.is-charter-privacy"
    assert_select "body.is-paper-hall", count: 0
    assert_select "#privacy_charter.charter-journey--privacy"
    assert_select ".charter-journey-hero[style*=?]", generated_media_src("media/legal/privacy-charter-celestial-light-v1.webp", format: "webp")
    assert_select ".charter-journey-intro h1", text: I18n.t("privacy.title")
    assert_select ".charter-journey-story .charter-journey-act", count: 13
    assert_select ".charter-journey-act h2", text: I18n.t("privacy.ask.title")
    assert_select ".charter-journey-act p", text: I18n.t("privacy.ask.body")
    assert_select ".charter-journey-act p", text: I18n.t("privacy.cookies.third_parties")
    assert_select ".charter-journey-act p", text: I18n.t("privacy.cookies.mute")
    assert_select ".charter-journey-act h2", text: I18n.t("privacy.youtube.title")
    assert_select ".charter-journey-act p", text: I18n.t("privacy.youtube.body")
    assert_select ".charter-journey-act p", text: I18n.t("privacy.youtube.choice")
    assert_select ".charter-journey-act h2", text: I18n.t("privacy.push.title")
    assert_select ".charter-journey-act p", text: I18n.t("privacy.push.basis")
    assert_select ".charter-journey-act p", text: I18n.t("privacy.push.retention")
    assert_select ".charter-cookies dt", text: "noche_device"
    assert_select ".charter-cookies dt", text: "noche_ward"
    assert_select ".charter-cookies dt", text: "noche_player, noche_client"
    assert_select "a.quiet-link[href=?]", "https://www.aepd.es", text: I18n.t("privacy.rights.aepd")
    assert_select "a[href='mailto:tracy.loisel@gmail.com']"
    assert_select ".charter-journey-foot", count: 0
    assert_select ".charter-journey-story a[href=?]", legal_path, count: 0
    assert_select ".navigation-dock .navigation-dock__item", count: 5
    assert_select ".home-menu.is-hud[data-hud-theme='celestial-light'] .quiz-hud[data-hud-theme='celestial-light']"
    assert_select ".hall-sheet", count: 0
    assert_select ".story-ticks", count: 0
    assert_select ".btn.btn-gold", count: 0
  end

  test "stats is a public Celestial Dark chronicle with five chapters" do
    get platform_stats_path
    assert_response :success
    assert_select "body.is-paper-hall.is-celestial-dark.is-stats"
    assert_select "#stats_page.stats-page"
    assert_select ".home-menu.is-hud[data-hud-theme='celestial-dark'] .quiz-hud[data-hud-theme='celestial-dark']", count: 1
    assert_select ".stats-header h1", text: I18n.t("stats.title")
    assert_select ".stats-header-lede", text: I18n.t("stats.lede")
    assert_select "section.stats-chapter h2", count: 5
    assert_select "section.stats-chapter h2 .stats-chapter-num", count: 5
    assert_select "section.stats-chapter h2", text: /La casa/
    assert_select "section.stats-chapter h2", text: /El camino/
    assert_select "section.stats-chapter h2", text: /Encuentros/
    assert_select "section.stats-chapter h2", text: /Invitaciones/
    assert_select "section.stats-chapter h2", text: /Liga mundial/
    assert_select ".stats-invitations"
    assert_select ".stats-invitations-medallion img[src=?]", generated_media_src("media/social/icon-share-medallion-v1.png")
    assert_select ".stats-invitation-step", count: 4
    assert_select ".stats-invitations-conversion"
    assert_select ".stats-tile"
    assert_select ".stats-langs"
    assert_select ".stats-path-circle"
    assert_select ".stats-path-svg"
    assert_select ".stats-world-list"
    assert_select "nav.navigation-dock .navigation-dock__item", count: 5
    assert_select "nav.navigation-dock a.navigation-dock__item.is-active[href=?]", root_path, count: 1
    assert_select ".stats-about[href=?]", about_path
    assert_select ".stats-about .stats-about-title", text: I18n.t("stats.about.title")
    assert_select "dl.paper-facts", count: 0
    assert_select ".stats-world-name", text: "Carmen"
    assert_select ".stats-world-name", text: /García/, count: 0
    assert_select ".stats-world-row.is-champion[data-place='1']", count: 1
    assert_select ".stats-world-score .stats-world-score-picto", count: css_select(".stats-world-score").size
    assert_select ".stats-world-place", text: /#{I18n.t("countries.ES")}/
    assert_select ".stats-page", text: /1833/, count: 0
    assert_select ".street-liga-podium", count: 0
    assert_select ".story-ticks", count: 0
    assert_select ".btn.btn-gold", count: 0
    assert_select "nav.navigation-dock a[href=?]", platform_stats_path, count: 0
  end

  test "stats shows an honest empty world when no pack is finished" do
    QuizAnswer.delete_all
    QuizRun.delete_all
    get platform_stats_path
    assert_response :success
    assert_select ".stats-empty", text: I18n.t("stats.world.empty")
  end
end
