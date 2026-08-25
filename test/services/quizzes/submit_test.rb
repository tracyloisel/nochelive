require "test_helper"

class Quizzes::SubmitTest < ActiveSupport::TestCase
  setup do
    @digest = GameSession.digest_token("submit-device")
    @frame = Quizzes::Draw.call(device_digest: @digest)
    @run = @frame.run
    @question = @frame.question
  end

  test "grades a correct pick and adds points" do
    answer = Quizzes::Submit.call(run: @run, choice_key: @question.correct_choice)
    assert answer.correct?
    assert_equal @question.points, @run.reload.score
  end

  test "grades a miss without points" do
    wrong = (@question.choices.map { |choice| choice["key"] } - [ @question.correct_choice ]).first
    answer = Quizzes::Submit.call(run: @run, choice_key: wrong)
    refute answer.correct?
    assert_equal 0, @run.reload.score
  end

  test "is idempotent for the same question" do
    one = Quizzes::Submit.call(run: @run, choice_key: @question.correct_choice)
    two = Quizzes::Submit.call(run: @run, choice_key: "nope")
    assert_equal one.id, two.id
    assert one.reload.correct?
    assert_equal @question.points, @run.reload.score
  end

  test "a late tap is always wrong" do
    @run.update!(ends_at: 1.minute.ago)
    answer = Quizzes::Submit.call(run: @run, choice_key: @question.correct_choice)
    refute answer.correct?
    assert_equal 0, @run.reload.score
  end

  test "refuses a finished run" do
    @run.update!(status: "finished")
    assert_raises(RuntimeError) { Quizzes::Submit.call(run: @run, choice_key: @question.correct_choice) }
  end
end
