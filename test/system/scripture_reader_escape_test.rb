require "application_system_test_case"

class ScriptureReaderEscapeTest < ApplicationSystemTestCase
  setup do
    Scriptures::Read.fetcher = ->(*) { file_fixture("scripture_1_sam_16.json").read }
  end

  teardown do
    Scriptures::Read.fetcher = nil
  end

  test "quiz reader loads from the configured asset host and reopens after closing" do
    person = people(:pili)
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.post enter_ward_path, params: { code: person.ward.code }
    session.post street_profile_path, params: { person_id: person.id, favorite_year: person.favorite_year }

    visit root_path
    session.cookies.to_hash.each do |name, value|
      page.driver.browser.manage.add_cookie(name:, value:, path: "/")
    end
    page.driver.browser.manage.add_cookie(name: Locale::COOKIE.to_s, value: "fr", path: "/")
    visit root_path
    find(".hub-play").click if page.has_css?(".hub-play", wait: 1)
    assert_selector "#street_quiz .choice-btn"
    QuizRun.order(:id).last.update!(pack_id: "coronas", position: 1, score: 0, ends_at: nil, status: "open")
    visit jugar_path

    find(".choice-btn[data-choice-key='samuel']").click
    assert_selector "#street_quiz.is-actions-ready .quiz-scripture"

    # Serve the real CSS from this same test server under a different origin,
    # reproducing the production asset host without an external dependency.
    page.execute_script(<<~JS)
      const stylesheet = new URL(document.body.dataset.scriptureLauncherStylesheetValue, document.baseURI);
      stylesheet.hostname = location.hostname === "localhost" ? "127.0.0.1" : "localhost";
      document.documentElement.dataset.assetHost = stylesheet.origin;
      document.body.dataset.scriptureLauncherStylesheetValue = stylesheet.href;
    JS

    2.times do
      find(".quiz-scripture").click
      assert_selector "#scripture_reader .scripture-reader-room[data-scripture-runtime='ready']"
      assert_selector "#scripture-title", text: "1 Samuel 16"
      assert_selector ".scripture-verse[data-scripture-verse-number='13'].is-focus"
      assert_equal "fixed", page.evaluate_script("getComputedStyle(document.querySelector('.scripture-reader-room')).position")
      assert_selector "head link[data-runtime-stylesheet='scripture']", visible: :all

      find(".reader-close").click
      assert_no_selector "#scripture_reader .scripture-reader-room"
      assert_selector ".quiz-scripture:focus"
      assert_selector "#street_quiz.is-settled"
    end
  end

  test "Escape closes a reader setting dialog before it closes the reader" do
    visit scripture_path("ot/1-sam/16", cite: "1 Samuel 16:13", locale: :fr)

    assert_selector ".scripture-reader-room", wait: 8
    find(".reader-aa-button").click
    assert_selector "dialog.reader-settings-dialog[open]", wait: 5

    find("dialog.reader-settings-dialog").send_keys(:escape)

    assert_no_selector "dialog.reader-settings-dialog[open]", wait: 5
    assert_selector ".scripture-reader-room", wait: 5
  end

  test "the illustration preference hides inline chapter images but keeps the heading artwork" do
    visit scripture_path("ot/1-sam/16", cite: "1 Samuel 16:13", locale: :fr)

    assert_selector ".reader-chapter-art", visible: true, wait: 8
    assert_selector ".reader-verses .scripture-illustration[data-after-verse='13']", visible: true
    find(".reader-aa-button").click

    within "fieldset.reader-illustration-options" do
      find("label", text: "Non", exact_text: true).click
    end
    assert_selector ".scripture-reader-room[data-reader-illustrations='false']", visible: true
    assert_selector ".reader-chapter-art", visible: true
    assert_no_selector ".reader-verses .scripture-illustration", visible: true

    within "fieldset.reader-illustration-options" do
      find("label", text: "Oui", exact_text: true).click
    end
    assert_selector ".reader-chapter-art", visible: true
    assert_selector ".reader-verses .scripture-illustration[data-after-verse='13']", visible: true
  end
end
