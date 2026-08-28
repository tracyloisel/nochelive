require "test_helper"

class ScripturesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Scriptures::Read.fetcher = ->(*) { file_fixture("scripture_1_sam_16.json").read }
  end

  teardown do
    Scriptures::Read.fetcher = nil
  end

  test "shows a chapter in a fullscreen reader" do
    get scripture_path("ot/1-sam/16", cite: "1 Samuel 16:13")

    assert_response :success
    assert_select ".scripture-veil[role=dialog][data-stage-bed-value=study_refuge]"
    assert_select "#scripture-title", text: "1 Samuel 16"
    assert_select ".scripture-summary", text: /Jehová escoge a David/
    assert_select ".scripture-verse", count: 3
    assert_select ".scripture-verse.is-focus", text: /cuerno del aceite/
    assert_select ".scripture-verse.is-focus[data-scripture-focus]"
    assert_select ".scripture-close[aria-label=?]", I18n.t("quiz.scripture_close")
    assert_select "a.quiet-link[href*='churchofjesuschrist.org'][target=_blank]", text: I18n.t("quiz.scripture_open_site")
    assert_select "turbo-frame#scripture_reader"
  end

  test "renders the reader inside the turbo frame on a frame request" do
    get scripture_path("ot/1-sam/16", cite: "1 Samuel 16:13"),
        headers: { "Turbo-Frame" => "scripture_reader" }

    assert_response :success
    assert_select "turbo-frame#scripture_reader .scripture-veil[data-stage-bed-value=study_refuge]"
    assert_select "body", count: 0
  end

  test "unknown study is not found" do
    get "/escrituras/ot/gen/1"

    assert_response :not_found
  end

  test "a failed fetch still shows the overlay with a way out" do
    Scriptures::Read.fetcher = ->(*) { nil }
    get scripture_path("ot/1-sam/16")

    assert_response :success
    assert_select ".scripture-error", text: I18n.t("quiz.scripture_error")
    assert_select "a.quiet-link[href*='churchofjesuschrist.org']"
  end

  test "reader title is ink and the cited verse uses a gold metal mark" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read
    title = css[/\.scripture-head h1 \{[^}]+\}/m]
    assert title, "expected .scripture-head h1 rule"
    assert_match(/color: var\(--ink\)/, title)
    refute_match(/gold/, title)
    focus = css[/\.scripture-verse\.is-focus \{[^}]+\}/m]
    assert focus, "expected .scripture-verse.is-focus rule"
    assert_match(/border-inline-start: 3px solid var\(--gold-deep\)/, focus)
    refute_match(/color: var\(--gold/, focus)
  end

  test "reads the chapter in the active locale" do
    uri = nil
    Scriptures::Read.fetcher = ->(value) { uri = value; file_fixture("scripture_1_sam_16.json").read }
    patch locale_path, params: { locale: "fr" }
    get scripture_path("ot/1-sam/16", cite: "1 Samuel 16:13")

    assert_response :success
    assert_includes uri.to_s, "lang=fra"
    assert_includes uri.to_s, "uri=%2Fscriptures%2Fot%2F1-sam%2F16"
  end

  test "serves an indexable localized page for 2 Samuel 2 verse 1" do
    Scriptures::Read.fetcher = ->(*) { file_fixture("scripture_2_sam_2.json").read }

    get scripture_passage_path(
      locale: "fr", scripture_section: "bible", book: "2-samuel", chapter: 2, verse: 1
    )

    assert_response :success
    assert_select "html[lang=fr]"
    assert_select "title", text: /2 Samuel 2:1/
    assert_select "meta[name=description][content*='2 Samuel 2:1']", count: 1
    assert_select "link[rel=canonical][href$='/fr/bible/2-samuel/2/1']", count: 1
    assert_select "link[rel=alternate][hreflang=fr]", count: 1
    assert_select "link[rel=alternate][hreflang=es]", count: 1
    assert_select "link[rel=alternate][hreflang=pt-br]", count: 1
    assert_select "link[rel=alternate][hreflang=en]", count: 1
    assert_select "script[type='application/ld+json']", count: 1
    assert_select "h1", text: "2 Samuel 2:1"
    assert_select ".scripture-verse.is-focus", text: /David consulta/
    assert_select ".home-menu.is-hud .quiz-hud", count: 1
    assert_select ".navigation-dock .navigation-dock__item.is-active", text: I18n.t("hub.nav_word", locale: :fr)
    assert_select ".scripture-seo-foot a[href*='churchofjesuschrist.org']", count: 1
    assert_select ".scripture-seo-foot .btn.btn-gold", text: "Apprends la bible en t'amusant"
    assert_select ".home-menu .mute", count: 0
    assert_select ".home-menu .lang-switch", count: 0
    assert_select ".chrome-tools", count: 0
  end
end
