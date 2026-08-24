require "test_helper"

class TapRunTest < ActiveSupport::TestCase
  setup do
    @round = round_runs(:david_goliath)
    @round.update!(phase: "open")
    @team = teams(:leones)
    @player = players(:lucia)
  end

  test "counts taps and awards once at the goal" do
    goal = @round.definition.tap_goal
    run = nil
    goal.times do
      run = TapRun.tap!(round_run: @round, team: @team, player: @player)
    end
    assert run.finished?
    assert_equal goal, run.taps
    assert_equal 1, @team.score_events.where(kind: "rapid_tap").count

    again = TapRun.tap!(round_run: @round, team: @team, player: @player)
    assert_equal run.id, again.id
    assert_equal 1, @team.score_events.where(kind: "rapid_tap").count
  end

  test "rejects taps when the round is not open" do
    @round.lock!
    assert_raises(RuntimeError) do
      TapRun.tap!(round_run: @round, team: @team, player: @player)
    end
  end
end
