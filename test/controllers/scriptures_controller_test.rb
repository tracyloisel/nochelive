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
    assert_select "p.scripture-verse[data-scripture-target=verse]", count: 3
    assert_select ".scripture-verse.is-focus [data-scripture-verse-text]", text: /cuerno del aceite/
    assert_select ".scripture-verse.is-focus[data-scripture-focus]"
    assert_select ".scripture-veil[data-scripture-reference='ot/1-sam/16'][data-scripture-read-url=?][data-scripture-share-url$='/es/biblia/1-samuel/16']", scripture_reads_path
    assert_select ".scripture-selection-hint", count: 0
    assert_select ".scripture-share-trigger[hidden][data-action*='scripture#openShare'][aria-label=?]", I18n.t("quiz.scripture_share")
    assert_select "dialog.scripture-share-dialog[tabindex='-1'][data-scripture-target=shareDialog]"
    assert_select ".scripture-share-option[data-action='scripture#copyLink']", text: I18n.t("quiz.scripture_copy_link")
    assert_select ".scripture-share-option[data-scripture-target=whatsapp][href='https://wa.me/']", text: I18n.t("quiz.scripture_share_whatsapp")
    assert_select ".scripture-share-option[data-scripture-target=x][href='https://twitter.com/intent/tweet'] > span:last-child", text: I18n.t("quiz.scripture_share_x")
    assert_select ".scripture-share-remove[hidden][data-action='scripture#removeHighlight'] > span:last-child", text: I18n.t("quiz.scripture_remove_highlight")
    assert_select ".scripture-read-count[hidden][aria-live=polite]", text: "0 lecturas"
    assert_select ".scripture-illustration[data-after-verse=13]", count: 1
    assert_select ".scripture-illustration img[src='/media/quizzes/coronas/ungio_david.jpg'][loading=lazy]", count: 1
    assert_select ".scripture-close[type=button][data-action='click->scripture#close'][aria-label=?]", I18n.t("quiz.scripture_close")
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

  test "embeds the current profile highlights for the active scripture locale" do
    person = create_street_profile!(name: "Lectora")
    person.scripture_highlights.create!(
      reference: "ot/1-sam/16",
      locale: "fr",
      start_verse: 1,
      end_verse: 2,
      start_offset: 2,
      end_offset: 14
    )

    get scripture_path("ot/1-sam/16", cite: "1 Samuel 16:13", locale: "fr")

    assert_response :success
    assert_select ".scripture-veil[data-scripture-locale=fr][data-scripture-highlight-url=?]", scripture_highlights_path
    payload = JSON.parse(css_select("script[data-scripture-profile-highlights]").first.text)
    assert_equal [ {
      "start_verse" => 1,
      "end_verse" => 2,
      "start_offset" => 2,
      "end_offset" => 14
    } ], payload.map { |highlight| highlight.except("id") }
    assert_equal person.scripture_highlights.first.id, payload.first.fetch("id")
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

  test "reader title is ink and cited text is highlighted without verse cards" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read
    title = css[/\.scripture-head h1 \{[^}]+\}/m]
    assert title, "expected .scripture-head h1 rule"
    assert_match(/color: var\(--ink\)/, title)
    refute_match(/gold/, title)
    focus = css[/\.scripture-verse\.is-focus \[data-scripture-verse-text\] \{[^}]+\}/m]
    assert focus, "expected a text-level focus rule"
    assert_match(/background: color-mix\(in srgb, var\(--gold\)/, focus)
    refute_match(/border|border-radius/, focus)
    refute_match(/\.scripture-verse\.is-selected/, css)
    assert_match(/\.scripture-share-trigger \{[^}]*z-index: 100;[^}]*background: var\(--temple-gold-leaf/m, css)
    assert_match(/\.scripture-share-dialog \{[^}]*inset: 50% auto auto 50%;[^}]*transform: translate\(-50%, -46%\) scale\(\.96\)/m, css)
    assert_match(/\.scripture-share-dialog\[open\] \{[^}]*translate\(-50%, -50%\) scale\(1\)/m, css)
    assert_match(/@starting-style \{[\s\S]*?\.scripture-share-dialog\[open\]/, css)
    assert_match(/\.scripture-share-close \.picto-close circle \{ display: none; \}/, css)
    assert_match(/\.scripture-share-option\[hidden\] \{ display: none; \}/, css)
  end

  test "reader close control has an accessible mobile target and a clear vector icon" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read
    close = css.scan(/\.scripture-close \{[^}]+\}/m).join("\n")

    assert_match(/width: 3rem/, close)
    assert_match(/height: 3rem/, close)
    assert_match(/touch-action: manipulation/, close)
    assert_match(/\.scripture-close:focus-visible \{[^}]*outline:/m, css)
    assert_match(/\.scripture-close \.picto-close circle \{ fill: transparent; \}/, css)
  end

  test "shows the confirmed chapter count in the reader" do
    ScriptureChapterStat.create!(reference: "ot/1-sam/16", reads_count: 1)

    get scripture_path("ot/1-sam/16")

    assert_response :success
    assert_select ".scripture-read-count:not([hidden])", text: "1 lectura"
  end

  test "keeps scripture order by default and can sort a book by reads" do
    ScriptureChapterStat.create!(reference: "ot/1-sam/3", reads_count: 12)
    ScriptureChapterStat.create!(reference: "ot/1-sam/1", reads_count: 4)
    path = scripture_book_path(locale: "fr", scripture_section: "bible", book: "1-samuel")

    get path
    assert_response :success
    assert_equal %w[1 2 3], css_select(".scripture-chapter-grid > div > a strong").first(3).map(&:text)
    assert_select ".scripture-chapter-order a[aria-current=page]", text: "Ordre des Écritures"

    get path, params: { order: "popular" }
    assert_response :success
    assert_equal %w[3 1 2], css_select(".scripture-chapter-grid > div > a strong").first(3).map(&:text)
    assert_select ".scripture-chapter-order a[aria-current=page]", text: "Les plus lus"
    assert_select ".scripture-chapter-grid > div > a:first-child small", text: "12 lectures"
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
    assert_select ".scripture-veil[role=dialog][data-scripture-share-url$='/fr/bible/2-samuel/2']"
    assert_select "#scripture-title", text: "2 Samuel 2"
    assert_select ".scripture-verse.is-focus[data-scripture-verse-number='1']", text: /David consulta/
    assert_select ".scripture-share-trigger[hidden]"
    assert_select "dialog.scripture-share-dialog"
    assert_select ".home-menu .mute", count: 0
    assert_select ".home-menu .lang-switch", count: 0
    assert_select ".chrome-tools", count: 0
  end

  test "opens a readable verse-range deep link in the reader with rich sharing metadata" do
    get scripture_passage_path(
      locale: "es", scripture_section: "biblia", book: "1-samuel", chapter: 16, verse: "1-2"
    )

    assert_response :success
    assert_select "title", text: /1 Samuel 16:1–2/
    assert_select "link[rel=canonical][href$='/es/biblia/1-samuel/16/1-2']", count: 1
    assert_select "meta[property='og:url'][content$='/es/biblia/1-samuel/16/1-2']", count: 1
    assert_select "meta[property='og:title'][content*='1 Samuel 16:1–2']", count: 1
    assert_select "meta[property='og:description'][content*='1 Samuel 16:1–2']", count: 1
    assert_select "meta[property='og:image'][content$='/media/quizzes/coronas/ungio_david.jpg']", count: 1
    assert_select ".scripture-verse.is-focus", count: 2
    assert_select ".scripture-share-trigger[hidden]"
    assert_select "dialog.scripture-share-dialog .scripture-share-option", count: 4
  end

  test "rejects a backwards verse range" do
    get scripture_passage_path(
      locale: "es", scripture_section: "biblia", book: "1-samuel", chapter: 16, verse: "13-2"
    )

    assert_response :not_found
  end

  test "inserts available paintings in a public chapter and exposes the first one to search engines" do
    get scripture_chapter_path(
      locale: "fr", scripture_section: "bible", book: "1-samuel", chapter: 16
    )

    assert_response :success
    assert_select ".scripture-seo-reading .scripture-illustration[data-after-verse=13]", count: 1
    assert_select "meta[property='og:image'][content$='/media/quizzes/coronas/ungio_david.jpg']", count: 1
    assert_select "script[type='application/ld+json']", text: /primaryImageOfPage/
  end
end
