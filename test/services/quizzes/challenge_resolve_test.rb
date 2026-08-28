require "test_helper"

class Quizzes::ChallengeResolveTest < ActiveSupport::TestCase
  test "records a completed challenge in the viral funnel" do
    duel = street_duels(:pending_challenge)
    challenger = QuizRun.create!(
      device_digest: "challenger-funnel", person: duel.challenger_person, pack_id: duel.pack_id,
      position: 10, score: 50, status: "finished", opened_at: 1.hour.ago
    )
    opponent = QuizRun.create!(
      device_digest: "opponent-funnel", person: people(:carmen_garcia), pack_id: duel.pack_id,
      position: 10, score: 60, status: "finished", opened_at: 30.minutes.ago, street_duel: duel
    )
    duel.update!(challenger_run: challenger, challenger_score: 50, opponent_person: opponent.person, opponent_run: opponent, status: "challenger_done")

    assert_difference("ViralEvent.where(name: 'challenge_completed').count", 1) do
      Quizzes::ChallengeResolve.after_run!(run: opponent)
    end

    assert_equal duel.id, ViralEvent.order(:id).last.street_duel_id
  end

  test "resolves when both scores present" do
    duel = street_duels(:pili_vs_carmen)
    result = Quizzes::ChallengeResolve.call(duel:)
    assert result.duel.resolved?
    assert_equal people(:carmen_garcia), result.winner
    refute result.tie
    assert_equal(-3, result.duel.challenger_delta)
    assert_equal 12, result.duel.opponent_delta
  end

  test "tie has no winner" do
    duel = street_duels(:pili_vs_carmen)
    duel.update!(challenger_score: 80, opponent_score: 80)
    result = Quizzes::ChallengeResolve.call(duel:)
    assert result.duel.resolved?
    assert_nil result.winner
    assert result.tie
    assert_equal 1, result.duel.challenger_delta
    assert_equal 1, result.duel.opponent_delta
  end

  test "after_run! waits for the second score" do
    duel = street_duels(:pending_challenge)
    run = QuizRun.create!(
      device_digest: GameSession.digest_token("resolve-challenger"),
      person: people(:pili),
      pack_id: duel.pack_id,
      position: 10,
      score: 60,
      status: "finished",
      opened_at: 1.hour.ago
    )
    Quizzes::ChallengeResolve.after_run!(run:)
    duel.reload
    assert_equal "challenger_done", duel.status
    assert_equal 60, duel.challenger_score
    assert_equal run.id, duel.challenger_run_id
    refute duel.resolved?
  end

  test "after_run! resolves when the opponent finishes" do
    duel = street_duels(:pending_challenge)
    challenger_run = QuizRun.create!(
      device_digest: GameSession.digest_token("resolve-c"),
      person: people(:pili),
      pack_id: duel.pack_id,
      position: 10,
      score: 40,
      status: "finished",
      opened_at: 2.hours.ago
    )
    opponent_run = QuizRun.create!(
      device_digest: GameSession.digest_token("resolve-o"),
      person: people(:carmen_garcia),
      pack_id: duel.pack_id,
      position: 10,
      score: 90,
      status: "finished",
      opened_at: 1.hour.ago
    )
    duel.update!(
      challenger_run:,
      challenger_score: 40,
      status: "challenger_done",
      opponent_person: people(:carmen_garcia),
      opponent_run:
    )
    Quizzes::ChallengeResolve.after_run!(run: opponent_run)
    duel.reload
    assert duel.resolved?
    assert_equal 90, duel.opponent_score
    assert_equal people(:carmen_garcia), duel.winner_person
  end

  test "after_run! ignores an unfinished run so partial scores cannot win" do
    duel = street_duels(:pending_challenge)
    run = QuizRun.create!(
      device_digest: GameSession.digest_token("resolve-open"),
      person: people(:pili),
      pack_id: duel.pack_id,
      position: 3,
      score: 25,
      status: "open",
      opened_at: Time.current
    )
    Quizzes::ChallengeResolve.after_run!(run:)
    assert_equal "pending", duel.reload.status
    assert_nil duel.challenger_score
  end

  test "zero to zero is a resolved tie" do
    duel = street_duels(:pili_vs_carmen)
    duel.update!(challenger_score: 0, opponent_score: 0, status: "opponent_done")
    result = Quizzes::ChallengeResolve.call(duel:)
    assert result.duel.resolved?
    assert result.tie
    assert_nil result.winner
  end
end
