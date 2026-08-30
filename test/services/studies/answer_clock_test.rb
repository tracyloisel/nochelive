require "test_helper"

class Studies::AnswerClockTest < ActiveSupport::TestCase
  test "measures the time since the current study question opened" do
    at = Time.zone.parse("2026-08-30 10:00:00")
    run = StudyRun.new(asked_at: at - 4.25.seconds)

    assert_equal 4250, Studies::AnswerClock.elapsed_ms(run, at:)
  end

  test "caps abandoned study questions and never returns a negative duration" do
    at = Time.zone.parse("2026-08-30 10:00:00")

    assert_equal Studies::AnswerClock::MAX_DURATION_MS,
      Studies::AnswerClock.elapsed_ms(StudyRun.new(asked_at: at - 2.hours), at:)
    assert_equal 0, Studies::AnswerClock.elapsed_ms(StudyRun.new(asked_at: at + 2.seconds), at:)
  end
end
