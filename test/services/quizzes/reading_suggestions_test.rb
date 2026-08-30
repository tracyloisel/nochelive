require "test_helper"

class Quizzes::ReadingSuggestionsTest < ActiveSupport::TestCase
  test "keeps only the newest unresolved answer for each question and deduplicates readings" do
    person = people(:pili)
    pack = QuizDefinition.catalog.find_pack("coronas")
    first, second = pack.questions.first(2)
    old_run = completed_run(person:, suffix: "old")
    latest_run = completed_run(person:, suffix: "latest")

    answer_for(old_run, first, correct: false, at: 2.days.ago)
    answer_for(latest_run, first, correct: true, at: 1.day.ago)
    answer_for(latest_run, second, correct: false, at: Time.current)

    suggestions = Quizzes::ReadingSuggestions.call(person:)

    assert_equal [ second.scripture.study ], suggestions.map(&:study)
    assert_equal [ second.scripture.cite ], suggestions.map(&:cite)
  end

  private

    def completed_run(person:, suffix:)
      QuizRun.create!(
        person:, device_digest: "reading-suggestion-#{suffix}", pack_id: "coronas",
        position: 10, score: 0, status: "finished", opened_at: Time.current
      )
    end

    def answer_for(run, question, correct:, at:)
      QuizAnswer.create!(
        quiz_run: run, device_digest: run.device_digest, pack_id: run.pack_id,
        question_id: question.id, choice_key: question.correct_choice, correct:,
        created_at: at, updated_at: at
      )
    end
end
