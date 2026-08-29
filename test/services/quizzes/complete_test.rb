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
    refute summary.first
    assert summary.average
    assert_nil summary.standings
  end

  test "summary includes standings when ward and person exist" do
    digest = GameSession.digest_token("complete-person")
    person = people(:pili)
    run = Quizzes::Draw.call(device_digest: digest, person_id: person.id).run
    run.update!(position: 10)
    Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)
    Quizzes::Complete.call(run: run.reload)
    summary = Quizzes::Complete.summary(run, ward: person.ward, person:)
    assert summary.standings
    assert summary.pack_board
    assert summary.total_board
  end

  test "guest summary lists the rama pack board when the ward is known" do
    summary = Quizzes::Complete.summary(quiz_runs(:pili_coronas), ward: wards(:demo))
    assert_nil summary.standings
    assert summary.pack_board
    assert summary.pack_board.rows.any?
    assert summary.pack_board.rows.first.person.present?
  end

  test "average is honest when at least two finished runs exist" do
    pack = "placas"
    a = QuizRun.create!(device_digest: GameSession.digest_token("avg-a"), pack_id: pack, position: 10, score: 40, status: "finished", opened_at: Time.current)
    b = QuizRun.create!(device_digest: GameSession.digest_token("avg-b"), pack_id: pack, position: 10, score: 80, status: "finished", opened_at: Time.current)
    summary = Quizzes::Complete.summary(b)
    refute summary.first
    assert_equal 60, summary.average
    assert summary.n >= 2
    assert_equal 80, summary.score
    assert_equal 40, Quizzes::Complete.summary(a).score
  end

  test "first pack finish unlocks next pack id" do
    digest = GameSession.digest_token("unlock-first")
    run = Quizzes::StartPack.call(device_digest: digest, pack_id: "coronas").run
    run.update!(position: 10)
    Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)
    Quizzes::Complete.call(run: run.reload)
    assert_equal QuizDefinition.catalog.pack_ids.second, Quizzes::Complete.unlock_pack_id(run.reload)
  end

  test "summary records answered correct streak duration and last gain" do
    digest = GameSession.digest_token("complete-stats")
    run = Quizzes::Draw.call(device_digest: digest).run
    10.times do
      Quizzes::Submit.call(run: run.reload, choice_key: run.question.correct_choice)
      Quizzes::Advance.call(run: run.reload)
    end
    run.reload
    assert run.finished?
    summary = Quizzes::Complete.summary(run)
    assert_equal 10, summary.answered
    assert_equal 10, summary.correct
    assert_equal 10, summary.max_streak
    assert_equal 50, summary.base_score
    assert_equal 39, summary.streak_bonus
    assert_equal 89, summary.score
    assert_equal 10, summary.last_gain
    assert_equal 10, run.fire_count
    assert_equal 39, run.fire_bonus
    assert summary.duration_s >= 0
  end

  test "ceremony time is the sum of think times not the wall clock" do
    digest = GameSession.digest_token("complete-think-time")
    run = Quizzes::Draw.call(device_digest: digest).run
    run.update!(opened_at: 1.hour.ago, asked_at: 5.seconds.ago)
    Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)
    Quizzes::Advance.call(run: run.reload)
    run.reload.update!(asked_at: 7.seconds.ago)
    Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)
    summary = Quizzes::Complete.summary(run.reload)
    assert_in_delta 12, summary.duration_s, 1
    assert summary.duration_s < 60
  end

  test "legacy answers without duration_ms keep wall-clock time" do
    digest = GameSession.digest_token("complete-legacy-time")
    opened = Time.zone.parse("2026-08-27 15:00:00")
    run = QuizRun.create!(
      device_digest: digest,
      pack_id: "coronas",
      position: 10,
      score: 40,
      status: "finished",
      opened_at: opened
    )
    travel_to opened + 9.minutes do
      run.quiz_answers.create!(
        device_digest: digest,
        pack_id: "coronas",
        question_id: run.question.id,
        choice_key: "x",
        correct: true
      )
    end
    summary = Quizzes::Complete.summary(run.reload)
    assert_equal 540, summary.duration_s
  end
end
