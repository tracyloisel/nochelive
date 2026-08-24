require "test_helper"

class Rounds::RevealTest < ActiveSupport::TestCase
  test "reveals an open round" do
    round = round_runs(:salomon)
    Rounds::Reveal.call(round:)
    assert round.reload.revealed?
    assert round.revealed_at.present?
  end

  test "is a no-op when already revealed" do
    round = round_runs(:salomon)
    round.reveal!
    assert_nothing_raised { Rounds::Reveal.call(round:) }
    assert round.reload.revealed?
  end
end
