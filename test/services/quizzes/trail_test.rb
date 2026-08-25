require "test_helper"

class Quizzes::TrailTest < ActiveSupport::TestCase
  setup do
    @digest = GameSession.digest_token("trail-device")
    @frame = Quizzes::Draw.call(device_digest: @digest)
    @run = @frame.run
  end

  test "starts with one pack and the first question" do
    steps = Quizzes::Trail.call(run: @run)
    assert_equal 2, steps.size
    assert steps.first.pack?
    assert steps.last.question?
    assert_equal :current, steps.last.state
  end

  test "marks answered steps on the path" do
    Quizzes::Submit.call(run: @run, choice_key: @frame.question.correct_choice)
    Quizzes::Advance.call(run: @run.reload)
    wrong = @run.pack.question_at(2)
    bad = wrong.choices.map { |choice| choice.is_a?(Hash) ? (choice["key"] || choice[:key]) : choice.to_s }.find { |key| key != wrong.correct_choice }
    Quizzes::Submit.call(run: @run.reload, choice_key: bad)

    steps = Quizzes::Trail.call(run: @run.reload)
    first = steps.find { |step| step.question? && step.position == 1 }
    second = steps.find { |step| step.question? && step.position == 2 }
    assert_equal :correct, first.state
    assert_equal :wrong, second.state
    assert first.jumpable?
    assert second.jumpable?
  end
end
