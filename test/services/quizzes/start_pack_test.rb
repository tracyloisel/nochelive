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
end
