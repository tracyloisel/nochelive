require "test_helper"

class Rounds::ForwardTest < ActiveSupport::TestCase
  test "opens the next round after a quiz answer" do
    round_runs(:salomon).update!(phase: "completed")
    round = round_runs(:rey_o_profeta)
    round.update!(phase: "open", opened_at: Time.current)
    nxt = round_runs(:david_goliath)
    Answers::Submit.call(round:, team: teams(:leones), player: players(:lucia), body: "false")

    Rounds::Forward.call(round:, team: teams(:leones))

    assert round.reload.completed?
    assert nxt.reload.open?
  end

  test "requires a quiz answer first" do
    round = round_runs(:rey_o_profeta)
    round.update!(phase: "open", opened_at: Time.current)
    assert_raises(RuntimeError) { Rounds::Forward.call(round:, team: teams(:leones)) }
  end
end
