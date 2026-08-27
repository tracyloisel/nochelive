require "test_helper"

class Quizzes::ExpireTest < ActiveSupport::TestCase
  test "expires an unanswered question as wrong" do
    digest = GameSession.digest_token("expire-device")
    run = Quizzes::Draw.call(device_digest: digest).run
    run.update!(ends_at: 20.seconds.from_now)
    answer = Quizzes::Expire.call(run:)
    refute answer.correct?
    assert_nil answer.choice_key
    assert run.reload.settled?
  end

  test "leaves an existing answer alone" do
    digest = GameSession.digest_token("expire-kept")
    run = Quizzes::Draw.call(device_digest: digest).run
    kept = Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)
    assert_equal kept.id, Quizzes::Expire.call(run: run.reload).id
    assert kept.reload.correct?
  end

  test "a timed miss records the question clock" do
    digest = GameSession.digest_token("expire-timed")
    run = Quizzes::Draw.call(device_digest: digest).run
    question = run.pack.question_at(4)
    asked = 20.seconds.ago
    run.update!(position: 4, asked_at: asked, ends_at: asked + question.duration.seconds)
    answer = Quizzes::Expire.call(run: run.reload)
    refute answer.correct?
    assert_in_delta 20_000, answer.duration_ms, 200
  end
end
