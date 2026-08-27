require "test_helper"

class Quizzes::AskClockTest < ActiveSupport::TestCase
  test "untimed opening has asked_at and no deadline" do
    question = QuizDefinition.catalog.find_pack("coronas").question_at(1)
    refute question.timed?
    at = Time.zone.parse("2026-08-27 15:00:00")
    attrs = Quizzes::AskClock.opening_attrs(question, at:)
    assert_equal at, attrs[:asked_at]
    assert_nil attrs[:ends_at]
  end

  test "timed opening sets the deadline from asked_at" do
    question = QuizDefinition.catalog.find_pack("coronas").question_at(4)
    assert question.timed?
    at = Time.zone.parse("2026-08-27 15:00:00")
    attrs = Quizzes::AskClock.opening_attrs(question, at:)
    assert_equal at, attrs[:asked_at]
    assert_equal at + 20.seconds, attrs[:ends_at]
  end

  test "elapsed_ms is the think time since asked_at" do
    run = quiz_runs(:open_coronas)
    question = run.question
    run.asked_at = 4.seconds.ago
    ms = Quizzes::AskClock.elapsed_ms(run, question:, at: Time.current)
    assert_in_delta 4000, ms, 200
  end

  test "timed elapsed_ms never exceeds the question clock" do
    run = quiz_runs(:open_coronas)
    question = run.pack.question_at(4)
    run.asked_at = 40.seconds.ago
    ms = Quizzes::AskClock.elapsed_ms(run, question:, at: Time.current)
    assert_equal 20_000, ms
  end
end
