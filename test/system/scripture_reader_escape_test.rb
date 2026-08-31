require "application_system_test_case"

class ScriptureReaderEscapeTest < ApplicationSystemTestCase
  setup do
    Scriptures::Read.fetcher = ->(*) { file_fixture("scripture_1_sam_16.json").read }
  end

  teardown do
    Scriptures::Read.fetcher = nil
  end

  test "Escape closes a reader setting dialog before it closes the contextual reader" do
    visit scripture_library_path(preview: 1, locale: :fr)
    find(".scripture-library-row[data-library-row='resume']").click

    assert_selector "turbo-frame#scripture_reader .scripture-reader-room", wait: 8
    find(".reader-aa-button").click
    assert_selector "dialog.reader-settings-dialog[open]", wait: 5

    find("dialog.reader-settings-dialog").send_keys(:escape)

    assert_no_selector "dialog.reader-settings-dialog[open]", wait: 5
    assert_selector "turbo-frame#scripture_reader .scripture-reader-room", wait: 5
  end
end
