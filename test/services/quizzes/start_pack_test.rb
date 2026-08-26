require "test_helper"

class Quizzes::StartPackTest < ActiveSupport::TestCase
  test "starts first pack" do
    digest = GameSession.digest_token("start-pack")
    frame = Quizzes::StartPack.call(device_digest: digest, pack_id: "coronas")
    assert frame.run.open?
    assert_equal "coronas", frame.run.pack_id
  end

  test "locked pack raises" do
    digest = GameSession.digest_token("start-locked")
    assert_raises(Quizzes::StartPack::Locked) do
      Quizzes::StartPack.call(device_digest: digest, pack_id: "placas")
    end
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
