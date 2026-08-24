require "test_helper"

class Rounds::LockTest < ActiveSupport::TestCase
  test "locks an open round" do
    round = round_runs(:freeze_saul)
    round.update!(phase: "open", opened_at: Time.current)
    Rounds::Lock.call(round:)
    assert round.reload.locked?
    assert round.locked_at.present?
  end

  test "is a no-op when already locked" do
    round = round_runs(:salomon)
    round.lock!
    assert_nothing_raised { Rounds::Lock.call(round:) }
    assert round.reload.locked?
  end
end
