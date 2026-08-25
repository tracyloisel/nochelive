require "test_helper"

class Quizzes::RewindTest < ActiveSupport::TestCase
  setup do
    @digest = GameSession.digest_token("rewind-device")
    @frame = Quizzes::Draw.call(device_digest: @digest)
    @run = @frame.run
  end

  test "stays on the first unanswered question" do
    same = Quizzes::Rewind.call(run: @run)
    assert_equal 1, same.run.position
    assert same.asking?
  end

  test "returns to a prior settled question without dropping the current ask" do
    Quizzes::Submit.call(run: @run, choice_key: @frame.question.correct_choice)
    Quizzes::Advance.call(run: @run.reload)
    assert_equal 2, @run.reload.position
    assert @run.quiz_answers.find_by(question_id: @run.pack.question_at(2).id).nil?

    back = Quizzes::Rewind.call(run: @run.reload)
    assert_equal 1, back.run.position
    assert back.settled?
    assert @run.reload.quiz_answers.find_by(question_id: @run.pack.question_at(2).id).nil?
  end

  test "reopens a finished pack on the last settled question" do
    @run.update!(position: 10)
    Quizzes::Submit.call(run: @run, choice_key: @run.question.correct_choice)
    Quizzes::Complete.call(run: @run.reload)
    back = Quizzes::Rewind.call(run: @run.reload)
    assert back.settled?
    assert_equal 10, back.run.position
    assert back.run.open?
  end
end
