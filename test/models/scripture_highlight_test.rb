require "test_helper"

class ScriptureHighlightTest < ActiveSupport::TestCase
  test "accepts an exact range in a known scripture chapter" do
    highlight = ScriptureHighlight.new(
      person: people(:pili),
      reference: "ot/1-sam/16",
      locale: "fr",
      start_verse: 1,
      end_verse: 2,
      start_offset: 2,
      end_offset: 14,
      selected_text: "  dit   l’Éternel à Samuel  "
    )

    assert_predicate highlight, :valid?
    assert_equal "dit l’Éternel à Samuel", highlight.selected_text
  end

  test "rejects an empty or unknown range" do
    highlight = ScriptureHighlight.new(
      person: people(:pili),
      reference: "unknown/book/1",
      locale: "fr",
      start_verse: 2,
      end_verse: 2,
      start_offset: 14,
      end_offset: 14
    )

    assert_not highlight.valid?
    assert highlight.errors.added?(:reference, :invalid)
    assert highlight.errors.added?(:end_offset, :greater_than, count: 14)
  end
end
