require "test_helper"

class Votes::CastTest < ActiveSupport::TestCase
  setup do
    @round = round_runs(:vote_solomon)
    @round.update!(phase: "open", opened_at: Time.current)
    Ballot.delete_all
  end

  test "rejects a vote for your own team" do
    assert_raises(RuntimeError) do
      Votes::Cast.call(round: @round, team: teams(:leones), player: players(:lucia), choice: teams(:leones))
    end
  end

  test "is idempotent for a player" do
    one = Votes::Cast.call(round: @round, team: teams(:leones), player: players(:lucia), choice: teams(:casa))
    two = Votes::Cast.call(round: @round, team: teams(:leones), player: players(:lucia), choice: teams(:casa))
    assert_equal one.id, two.id
  end

  test "tallies when every player has voted" do
    Votes::Cast.call(round: @round, team: teams(:leones), player: players(:lucia), choice: teams(:casa))
    assert @round.reload.open?

    Votes::Cast.call(round: @round, team: teams(:daniel_home), player: players(:daniel), choice: teams(:leones))
    assert @round.reload.locked?
    assert teams(:casa).reload.score_events.where(kind: "correct", round_run: @round).exists?
    assert teams(:leones).reload.score_events.where(kind: "correct", round_run: @round).exists?
  end
end
