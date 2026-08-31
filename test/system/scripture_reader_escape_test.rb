require "application_system_test_case"

class ScriptureReaderEscapeTest < ApplicationSystemTestCase
  setup do
    Scriptures::Read.fetcher = ->(*) { file_fixture("scripture_1_sam_16.json").read }
  end

  teardown do
    Scriptures::Read.fetcher = nil
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
