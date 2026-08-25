require "test_helper"

class Quizzes::CompleteTest < ActiveSupport::TestCase
  test "marks the run finished" do
    digest = GameSession.digest_token("complete-device")
    run = Quizzes::Draw.call(device_digest: digest).run
    run.update!(position: 10)
    Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)
    Quizzes::Complete.call(run: run.reload)
    assert run.reload.finished?
    summary = Quizzes::Complete.summary(run)
    assert summary.first
    assert_nil summary.average
  end

  test "average is honest when at least two finished runs exist" do
    pack = "coronas"
    a = QuizRun.create!(device_digest: GameSession.digest_token("avg-a"), pack_id: pack, position: 10, score: 40, status: "finished", opened_at: Time.current)
    b = QuizRun.create!(device_digest: GameSession.digest_token("avg-b"), pack_id: pack, position: 10, score: 80, status: "finished", opened_at: Time.current)
    summary = Quizzes::Complete.summary(b)
    refute summary.first
    assert_equal 60, summary.average
    assert summary.n >= 2
    assert_equal 80, summary.score
    assert_equal 40, Quizzes::Complete.summary(a).score
  end
end
