require "test_helper"

class Rounds::CompleteTest < ActiveSupport::TestCase
  test "completes the round and intros the next" do
    round = round_runs(:salomon)
    nxt = round_runs(:rey_o_profeta)

    Rounds::Complete.call(round:)

    assert round.reload.completed?
    assert_equal "intro", nxt.reload.phase
  end

  test "does not fail when the next round is already intro" do
    round = round_runs(:salomon)
    nxt = round_runs(:rey_o_profeta)
    nxt.update!(phase: "intro")

    assert_nothing_raised { Rounds::Complete.call(round:) }
    assert round.reload.completed?
    assert_equal "intro", nxt.reload.phase
  end

  test "intros the next round if a retry finds it still pending" do
    round = round_runs(:salomon)
    round.complete!
    nxt = round_runs(:rey_o_profeta)

    Rounds::Complete.call(round:)

    assert_equal "intro", nxt.reload.phase
  end

  test "finishes the night when completing the last round" do
    round = round_runs(:salomon)
    round.update_column(:position, 99)

    Rounds::Complete.call(round:)

    night = round.game_session.reload
    assert night.finished?
    assert night.season_applied_at.present?
  end
end
