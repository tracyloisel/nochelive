require "test_helper"

class Scriptures::RecordReadTest < ActiveSupport::TestCase
  test "counts a chapter once per reader and day" do
    at = Time.zone.parse("2026-08-28 12:00:00")

    first = nil
    assert_difference("ScriptureChapterRead.count", 1) do
      assert_difference("ScriptureChapterStat.count", 1) do
        first = record(reader: "reader-a", at:)
      end
    end
    assert first.counted
    assert_equal 1, first.reads_count

    duplicate = nil
    assert_no_difference("ScriptureChapterRead.count") do
      duplicate = record(reader: "reader-a", at: at + 2.hours, locale: :fr)
    end
    refute duplicate.counted
    assert_equal 1, duplicate.reads_count
  end

  test "counts another reader and the same reader on another day" do
    at = Time.zone.parse("2026-08-28 12:00:00")

    record(reader: "reader-a", at:)
    second_reader = record(reader: "reader-b", at:)
    next_day = record(reader: "reader-a", at: at + 1.day)

    assert second_reader.counted
    assert next_day.counted
    assert_equal 3, next_day.reads_count
    assert_equal 3, ScriptureChapterStat.count_for("ot/1-sam/16")
  end

  test "rejects a chapter that cannot be opened in the reader" do
    assert_raises(ArgumentError) do
      Scriptures::RecordRead.call(
        reference: "ot/gen/99",
        reader_digest: "reader-a",
        locale: :es
      )
    end
  end

  private

    def record(reader:, at:, locale: :es)
      Scriptures::RecordRead.call(
        reference: "ot/1-sam/16",
        reader_digest: GameSession.digest_token(reader),
        locale:,
        at:
      )
    end
end
