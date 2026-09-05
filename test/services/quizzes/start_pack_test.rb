require "test_helper"

class Quizzes::StartPackTest < ActiveSupport::TestCase
  test "starts first pack" do
    digest = GameSession.digest_token("start-pack")
    frame = Quizzes::StartPack.call(device_digest: digest, pack_id: "coronas")
    assert frame.run.open?
    assert_equal "coronas", frame.run.pack_id
    assert frame.run.asked_at
  end

  test "open pack resumes the same run" do
    digest = GameSession.digest_token("start-resume")
    first = Quizzes::StartPack.call(device_digest: digest, pack_id: "coronas").run
    first.update!(position: 4)
    again = Quizzes::StartPack.call(device_digest: digest, pack_id: "coronas").run
    assert_equal first.id, again.id
    assert_equal 4, again.position
  end

  test "locked pack raises" do
    digest = GameSession.digest_token("start-locked")
    assert_raises(Quizzes::StartPack::Locked) do
      Quizzes::StartPack.call(device_digest: digest, pack_id: "placas")
    end
  end

  test "a permanent pack selected by a published expedition can open independently" do
    digest = GameSession.digest_token("start-expedition-pack")
    pack_id = "psalms_every_breath"

    frame = Quizzes::StartPack.call(
      device_digest: digest,
      pack_id:,
      unlocked_pack_ids: [ pack_id ]
    )

    assert frame.run.open?
    assert_equal pack_id, frame.run.pack_id
  end

  test "the Word of Wisdom unlocks through the normal journey after inicios" do
    digest = GameSession.digest_token("start-dc89-after-inicios")
    QuizRun.create!(
      device_digest: digest,
      pack_id: "inicios",
      position: 10,
      score: 100,
      status: "finished",
      opened_at: Time.current
    )

    frame = Quizzes::StartPack.call(device_digest: digest, pack_id: "dc89_word_of_wisdom")

    assert frame.run.open?
    assert_equal "dc89_word_of_wisdom", frame.run.pack_id
    assert_equal "fast-dc89-q01", frame.question.id
  end

  test "finished pack starts a fresh run" do
    digest = GameSession.digest_token("start-replay")
    first = Quizzes::StartPack.call(device_digest: digest, pack_id: "coronas").run
    first.update!(position: 10)
    Quizzes::Submit.call(run: first, choice_key: first.question.correct_choice)
    Quizzes::Complete.call(run: first.reload)
    replay = Quizzes::StartPack.call(device_digest: digest, pack_id: "coronas").run
    assert replay.open?
    assert_equal "coronas", replay.pack_id
    assert_not_equal first.id, replay.id
  end
end
