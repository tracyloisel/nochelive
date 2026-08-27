require "test_helper"

class Quizzes::ChallengeAcceptTest < ActiveSupport::TestCase
  setup do
    @duel = street_duels(:pending_challenge)
    @carmen = people(:carmen_garcia)
    @digest = GameSession.digest_token("challenge-accept")
  end

  test "starts a fresh pack even when the pack is still locked" do
    @duel.update!(pack_id: "placas")
    frame = Quizzes::ChallengeAccept.call(duel: @duel, opponent_person: @carmen, device_digest: @digest)
    assert_equal "placas", frame.run.pack_id
    assert frame.run.open?
    assert_equal @carmen.id, @duel.reload.opponent_person_id
    assert_equal frame.run.id, @duel.opponent_run_id
    assert_equal @duel.id, frame.run.street_duel_id
  end

  test "does not reuse an in-progress pack run so scores stay comparable" do
    leftover = QuizRun.create!(
      device_digest: @digest,
      person_id: @carmen.id,
      pack_id: "coronas",
      position: 4,
      score: 30,
      status: "open",
      opened_at: 1.hour.ago
    )
    frame = Quizzes::ChallengeAccept.call(duel: @duel, opponent_person: @carmen, device_digest: @digest)
    assert_not_equal leftover.id, frame.run.id
    assert_equal 1, frame.run.position
    assert_equal 0, frame.run.score
  end

  test "resumes the same opponent open run instead of overwriting it" do
    first = Quizzes::ChallengeAccept.call(duel: @duel, opponent_person: @carmen, device_digest: @digest)
    second = Quizzes::ChallengeAccept.call(duel: @duel.reload, opponent_person: @carmen, device_digest: @digest)
    assert_equal first.run.id, second.run.id
  end

  test "rejects a second opponent" do
    Quizzes::ChallengeAccept.call(duel: @duel, opponent_person: @carmen, device_digest: @digest)
    assert_raises(Quizzes::ChallengeAccept::Taken) do
      Quizzes::ChallengeAccept.call(
        duel: @duel.reload,
        opponent_person: people(:carmen_lopez),
        device_digest: GameSession.digest_token("other-device")
      )
    end
    assert_equal @carmen.id, @duel.reload.opponent_person_id
  end

  test "rejects self challenges" do
    assert_raises(Quizzes::ChallengeAccept::Taken) do
      Quizzes::ChallengeAccept.call(
        duel: @duel,
        opponent_person: people(:pili),
        device_digest: @digest
      )
    end
  end

  test "rejects expired duels" do
    @duel.update!(expires_at: 1.hour.ago)
    assert_raises(Quizzes::ChallengeAccept::Expired) do
      Quizzes::ChallengeAccept.call(duel: @duel, opponent_person: @carmen, device_digest: @digest)
    end
  end
end
