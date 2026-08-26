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
    assert_select ".scripture-veil[role=dialog]"
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
    assert_select "turbo-frame#scripture_reader .scripture-veil"
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
end
