require "test_helper"

class Freezes::CatchTest < ActiveSupport::TestCase
  setup do
    @round = round_runs(:freeze_saul)
    @round.update!(phase: "open", opened_at: Time.current)
    @team = teams(:casa)
    @player = players(:daniel)
  end

  test "rejects a catch before the freeze" do
    assert_raises(RuntimeError) do
      Freezes::Catch.call(round: @round, team: @team, player: @player)
    end
  end

  test "awards correct inside the window" do
    Rounds::Lock.call(round: @round)
    Freezes::Catch.call(round: @round.reload, team: @team, player: @player)
    assert @team.reload.score_events.where(kind: "correct", round_run: @round).exists?
  end

  test "awards incorrect after the window" do
    Rounds::Lock.call(round: @round)
    travel 3.seconds do
      Freezes::Catch.call(round: @round.reload, team: teams(:leones), player: players(:lucia))
    end
    assert teams(:leones).reload.score_events.where(kind: "incorrect", round_run: @round).exists?
  end

  test "is idempotent for a team" do
    Rounds::Lock.call(round: @round)
    one = Freezes::Catch.call(round: @round.reload, team: @team, player: @player)
    two = Freezes::Catch.call(round: @round.reload, team: @team, player: @player)
    assert_equal one.id, two.id
    assert_equal 1, @team.reload.score_events.where(round_run: @round, kind: "correct").count
  end
end
