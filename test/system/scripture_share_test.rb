require "application_system_test_case"

class ScriptureShareTest < ApplicationSystemTestCase
  setup do
    Scriptures::Read.fetcher = ->(*) { file_fixture("scripture_1_sam_16.json").read }
  end

  teardown do
    Scriptures::Read.fetcher = nil
  end

  test "shares a native text selection by link, WhatsApp or X and restores it" do
    visit street_profile_path
    find("input[name=name]").set("Lectora")
    find("form.profile-gate-new button[type=submit]").click
    assert_selector "body.is-street-hub"

    visit scripture_path("ot/1-sam/16", cite: "1 Samuel 16:13", locale: "fr")

    assert_selector "p.scripture-verse[data-scripture-verse-number='13'].is-focus"
    assert_no_selector "button.scripture-verse"
    select_text(from_verse: 1, from_offset: 2, to_verse: 2, to_offset: 14)

    assert_selector ".scripture-share-trigger:not([hidden])"
    assert_selector ".scripture-veil[data-scripture-highlight-state=saved]"
    assert_equal 1, Person.find_by!(given_name: "Lectora").scripture_highlights.count
    assert_equal "dijo Jehová a Samuel: ve a Isaí de Belén. Y dijo Samuel:", Person.find_by!(given_name: "Lectora").scripture_highlights.first.selected_text
    assert_equal false, page.evaluate_script(<<~JS)
      (function() {
        var triggerRect = document.querySelector(".scripture-share-trigger").getBoundingClientRect();
        return Array.from(document.querySelectorAll("[data-scripture-verse-text]")).some(function(text) {
          return Array.from(text.getClientRects()).some(function(rect) {
            return !(triggerRect.right <= rect.left || triggerRect.left >= rect.right ||
              triggerRect.bottom <= rect.top || triggerRect.top >= rect.bottom);
          });
        });
      })()
    JS
    page.save_screenshot(Rails.root.join("tmp/scripture-selection.png")) if ENV["SCRIPTURE_SHARE_SCREENSHOT"] == "1"
    find(".scripture-share-trigger").click
    assert_selector "dialog.scripture-share-dialog[open]"
    assert_selector ".scripture-share-option", count: 4
    assert_selector ".scripture-share-remove:not([hidden])", text: I18n.t("quiz.scripture_remove_highlight", locale: :fr)
    page.evaluate_async_script("var done = arguments[0]; window.setTimeout(done, 320)")
    dialog_position = page.evaluate_script(<<~JS)
      (function() {
        var rect = document.querySelector(".scripture-share-dialog").getBoundingClientRect();
        return { x: rect.left + rect.width / 2, y: rect.top + rect.height / 2,
          viewportX: window.innerWidth / 2, viewportY: window.innerHeight / 2 };
      })()
    JS
    assert_in_delta dialog_position.fetch("viewportX"), dialog_position.fetch("x"), 2
    assert_in_delta dialog_position.fetch("viewportY"), dialog_position.fetch("y"), 2
    page.save_screenshot(Rails.root.join("tmp/scripture-share.png")) if ENV["SCRIPTURE_SHARE_SCREENSHOT"] == "1"

    page.execute_script(<<~JS)
      Object.defineProperty(navigator, "clipboard", {
        configurable: true,
        value: { writeText: async function(value) { window.__scriptureCopied = value } }
      })
    JS
    find(".scripture-share-option[data-action='scripture#copyLink']").click
    assert_selector ".scripture-share-status:not([hidden])", text: I18n.t("quiz.scripture_link_copied", locale: :fr)
    copied = page.evaluate_script("window.__scriptureCopied")
    assert_includes copied, "/fr/bible/1-samuel/16/1-2?"
    assert_includes copied, "start=2"
    assert_includes copied, "end=14"

    whatsapp = find(".scripture-share-option[data-scripture-target=whatsapp]")[:href]
    shared_text = CGI.parse(URI.parse(whatsapp).query).fetch("text").first
    shared_url = shared_text.lines.last.strip
    assert_includes shared_url, "/fr/bible/1-samuel/16/1-2"
    assert_includes shared_url, "start=2"
    assert_includes shared_url, "end=14"

    x_url = URI.parse(find(".scripture-share-option[data-scripture-target=x]")[:href])
    x_query = CGI.parse(x_url.query)
    assert_includes x_query.fetch("text").first, "1 Samuel 16:1–2"
    assert_equal shared_url, x_query.fetch("url").first

    visit shared_url
    assert_selector ".scripture-veil[role=dialog]"
    assert_selector ".scripture-share-trigger:not([hidden])"
    selected = page.evaluate_script("window.getSelection().toString().replace(/\\s+/g, ' ').trim()")
    assert_equal "dijo Jehová a Samuel: ve a Isaí de Belén. Y dijo Samuel:", selected
    assert_no_selector ".scripture-verse.is-focus"
    assert_selector "meta[property='og:url'][content$='/fr/bible/1-samuel/16/1-2']", visible: false

    visit scripture_path("ot/1-sam/16", cite: "1 Samuel 16:13", locale: "fr")
    persisted = page.evaluate_script(<<~JS)
      Array.from(CSS.highlights.get("scripture-profile-highlights") || []).map(function(range) {
        return range.toString().replace(/\s+/g, " ").trim()
      }).join(" ")
    JS
    assert_equal "dijo Jehová a Samuel: ve a Isaí de Belén. Y dijo Samuel:", persisted
    page.save_screenshot(Rails.root.join("tmp/scripture-highlight-persisted.png")) if ENV["SCRIPTURE_SHARE_SCREENSHOT"] == "1"

    find("[data-scripture-verse-number='1'] [data-scripture-verse-text]").click
    assert_selector ".scripture-share-trigger:not([hidden])"
    find(".scripture-share-trigger").click
    assert_selector ".scripture-share-remove:not([hidden])"
    find(".scripture-share-remove").click

    assert_no_selector "dialog.scripture-share-dialog[open]"
    assert_equal 0, Person.find_by!(given_name: "Lectora").scripture_highlights.count
    assert_equal 0, page.evaluate_script("CSS.highlights.get('scripture-profile-highlights')?.size || 0")
  end

  test "shares a saved highlight again from its history" do
    visit street_profile_path
    find("input[name=name]").set("Lectora")
    find("form.profile-gate-new button[type=submit]").click
    assert_selector "body.is-street-hub"

    person = Person.find_by!(given_name: "Lectora")
    person.scripture_highlights.create!(
      reference: "ot/1-sam/16", locale: "fr", start_verse: 1, end_verse: 2,
      start_offset: 2, end_offset: 14, selected_text: "Le Seigneur regarde au cœur"
    )
    2.times do |days_ago|
      ScriptureChapterRead.create!(
        person:, reference: "ot/1-sam/16", reader_digest: "same-reader",
        locale: "fr", read_on: days_ago.days.ago.to_date
      )
    end

    visit study_history_path(locale: "fr")

    assert_selector ".study-highlight-readers", text: I18n.t("study.highlight_reads", count: 1, locale: :fr)
    find(".study-highlight-share").click
    assert_selector "dialog.study-highlight-share-dialog[open]"
    assert_selector "#study-highlight-share-title",
      text: I18n.t("quiz.scripture_share_title", reference: "1 Samuel 16:1–2", locale: :fr)

    whatsapp = find("[data-study-highlight-share-target=whatsapp]")[:href]
    shared_text = CGI.parse(URI.parse(whatsapp).query).fetch("text").first
    assert_includes shared_text, "/fr/bible/1-samuel/16/1-2?"
    assert_includes shared_text, "start=2"
    assert_includes shared_text, "end=14"

    x_url = URI.parse(find("[data-study-highlight-share-target=x]")[:href])
    assert_includes CGI.parse(x_url.query).fetch("url").first, "/fr/bible/1-samuel/16/1-2?"
  end

  test "searches and filters a year of saved highlights" do
    visit street_profile_path
    find("input[name=name]").set("Lectora")
    find("form.profile-gate-new button[type=submit]").click
    assert_selector "body.is-street-hub"

    person = Person.find_by!(given_name: "Lectora")
    9.times do |index|
      person.scripture_highlights.create!(
        reference: "ot/1-sam/16", locale: "fr", start_verse: 1, end_verse: 1,
        start_offset: index, end_offset: index + 1, selected_text: "Parole de Samuel #{index + 1}"
      )
    end
    person.scripture_highlights.create!(
      reference: "nt/john/1", locale: "fr", start_verse: 1, end_verse: 1,
      start_offset: 0, end_offset: 5, selected_text: "Lumière unique de Jean"
    )

    visit study_history_path(locale: "fr")

    assert_selector ".study-highlight-results", text: I18n.t("study.highlight_results", count: 10, locale: :fr)
    assert_selector ".study-highlight-card", count: 8
    find(".study-highlight-search input").set("Lumiere unique")
    assert_selector ".study-highlight-card", count: 1, text: "Lumière unique de Jean"

    find(".study-highlight-search input").set("")
    find(".study-highlight-filters button", text: I18n.t("study.collections.new_testament", locale: :fr)).click
    assert_selector ".study-highlight-card", count: 1, text: /Jean 1:1/

    find(".study-highlight-filters button", text: I18n.t("study.highlight_filter_all", locale: :fr), exact_text: true).click
    assert_selector ".study-highlight-card", count: 8
    find(".study-highlights-more").click
    assert_selector ".study-highlight-card", count: 10
  end

  private

    def select_text(from_verse:, from_offset:, to_verse:, to_offset:)
      page.execute_script(<<~JS, from_verse, from_offset, to_verse, to_offset)
        var from = document.querySelector("[data-scripture-verse-number='" + arguments[0] + "'] [data-scripture-verse-text]");
        var to = document.querySelector("[data-scripture-verse-number='" + arguments[2] + "'] [data-scripture-verse-text]");
        var range = document.createRange();
        range.setStart(from.firstChild, arguments[1]);
        range.setEnd(to.firstChild, arguments[3]);
        var selection = window.getSelection();
        selection.removeAllRanges();
        selection.addRange(range);
        document.dispatchEvent(new Event("selectionchange"));
      JS
    end
end
