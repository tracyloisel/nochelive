require "test_helper"

class Quizzes::DrawTest < ActiveSupport::TestCase
  setup do
    @digest = GameSession.digest_token("draw-device")
  end

  test "starts the first pack for a new device" do
    frame = Quizzes::Draw.call(device_digest: @digest)
    assert_equal "coronas", frame.pack.id
    assert_equal 1, frame.run.position
    assert frame.asking?
    assert_equal "ungio_david", frame.question.id
    refute frame.question.timed?
    assert_nil frame.run.ends_at
  end

  test "returns the open run instead of starting another" do
    first = Quizzes::Draw.call(device_digest: @digest)
    second = Quizzes::Draw.call(device_digest: @digest)
    assert_equal first.run.id, second.run.id
    assert_equal 1, QuizRun.where(device_digest: @digest).count
  end

  test "shows a finished pack until advance starts the next" do
    run = QuizRun.create!(
      device_digest: @digest,
      pack_id: "coronas",
      position: 10,
      score: 40,
      status: "finished",
      opened_at: Time.current
    )
    frame = Quizzes::Draw.call(device_digest: @digest)
    assert_equal run.id, frame.run.id
    assert frame.done?
  end

  test "loops from milagros back to coronas" do
    QuizRun.create!(
      device_digest: @digest,
      pack_id: "milagros",
      position: 10,
      score: 10,
      status: "finished",
      opened_at: Time.current
    )
    frame = Quizzes::Advance.call(run: QuizRun.find_by!(device_digest: @digest, pack_id: "milagros"))
    assert_equal "coronas", frame.pack.id
    assert frame.run.open?
  end

  test "requires a device digest" do
    assert_raises(ArgumentError) { Quizzes::Draw.call(device_digest: "") }
  end
end
