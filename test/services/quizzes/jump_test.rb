require "test_helper"

class Quizzes::JumpTest < ActiveSupport::TestCase
  setup do
    @digest = GameSession.digest_token("jump-device")
    @frame = Quizzes::Draw.call(device_digest: @digest)
    @run = @frame.run
    Quizzes::Submit.call(run: @run, choice_key: @frame.question.correct_choice)
    Quizzes::Advance.call(run: @run.reload)
  end

  test "returns to a settled question" do
    back = Quizzes::Jump.call(run: @run.reload, position: 1)
    assert_equal 1, back.run.position
    assert back.settled?
  end

  test "rejects unanswered future steps" do
    assert_raises(RuntimeError) { Quizzes::Jump.call(run: @run.reload, position: 3) }
  end
end
