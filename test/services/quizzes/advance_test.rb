require "test_helper"

class Quizzes::AdvanceTest < ActiveSupport::TestCase
  setup do
    @digest = GameSession.digest_token("advance-device")
    @frame = Quizzes::Draw.call(device_digest: @digest)
    @run = @frame.run
  end

  test "moves to the next question after a tap" do
    Quizzes::Submit.call(run: @run, choice_key: @frame.question.correct_choice)
    nxt = Quizzes::Advance.call(run: @run.reload)
    assert_equal 2, nxt.run.position
    assert_equal "piedras_arroyo", nxt.question.id
    assert nxt.asking?
  end

  test "refuses to skip an unanswered question" do
    assert_raises(RuntimeError) { Quizzes::Advance.call(run: @run) }
  end

  test "completes the pack on the last question" do
    @run.update!(position: 10)
    question = @run.question
    Quizzes::Submit.call(run: @run, choice_key: question.correct_choice)
    done = Quizzes::Advance.call(run: @run.reload)
    assert done.done?
    assert @run.reload.finished?
    refute done.complete.first
    assert_equal @run.score, done.complete.score
  end

  test "opens the next pack after a finished hero" do
    @run.update!(position: 10)
    Quizzes::Submit.call(run: @run, choice_key: @run.question.correct_choice)
    Quizzes::Advance.call(run: @run.reload)
    nxt = Quizzes::Advance.call(run: @run.reload)
    assert_equal "placas", nxt.pack.id
    assert_equal 1, nxt.run.position
  end
end
