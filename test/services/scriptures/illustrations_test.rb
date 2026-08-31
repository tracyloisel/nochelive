require "test_helper"

class Scriptures::IllustrationsTest < ActiveSupport::TestCase
  Scripture = Struct.new(:study, :cite)
  Question = Struct.new(:id, :scripture, :presentation, :question, :answer) do
    def copy(field) = public_send(field)
  end

  test "finds the illustration whose citation covers a verse in the chapter" do
    chapter = chapter_for("ot/1-sam/16", [ 1, 2, 13 ])
    question = question_for("david", "ot/1-sam/16", "1 Samuel 16:11-13", "quizzes/coronas/ungio_david.jpg")

    illustrations = Scriptures::Illustrations.call(chapter:, questions: [ question ])

    assert_equal 1, illustrations.size
    illustration = illustrations.first
    assert_equal 13, illustration.anchor_verse
    assert_equal "1 Samuel 16:13", illustration.citation
    assert_equal "Qui est représenté ?", illustration.alt
    assert_equal "Qui est représenté ?", illustration.caption
  end

  test "keeps at most three paintings spread across an illustrated chapter" do
    chapter = chapter_for("nt/matt/13", (1..50).to_a)
    questions = (1..8).map do |verse|
      question_for("scene-#{verse}", "nt/matt/13", "Matthieu 13:#{verse}", "quizzes/secretos_reino/mostaza_crece.jpg")
    end

    illustrations = Scriptures::Illustrations.call(chapter:, questions:)

    assert_equal [ 1, 5, 8 ], illustrations.map(&:anchor_verse)
  end

  test "ignores media paths that are missing or unsafe" do
    chapter = chapter_for("ot/1-sam/16", [ 13 ])
    questions = [
      question_for("missing", "ot/1-sam/16", "1 Samuel 16:13", "quizzes/missing.jpg"),
      question_for("unsafe", "ot/1-sam/16", "1 Samuel 16:13", "../secret.jpg")
    ]

    assert_empty Scriptures::Illustrations.call(chapter:, questions:)
  end

  test "parses disjoint references only for the requested chapter" do
    ranges = Scriptures::Illustrations.verse_ranges("Génesis 11:30; 17:5-7, 15-19", 17)

    assert_equal [ 5..7, 15..19 ], ranges
  end

  private

    def chapter_for(study, verse_numbers)
      Scriptures::Read::Chapter.new(
        title: study == "nt/matt/13" ? "Matthieu 13" : "1 Samuel 16",
        summary: nil,
        verses: verse_numbers.map { |number| Scriptures::Read::Verse.new(number:, text: "Verset") },
        source_url: "https://example.test",
        study:,
        focus: []
      )
    end

    def question_for(id, study, cite, image)
      Question.new(
        id,
        Scripture.new(study, cite),
        { "image" => image },
        "Qui est représenté ?",
        "David est oint."
      )
    end
end
