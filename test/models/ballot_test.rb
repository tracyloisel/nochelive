require "test_helper"

class BallotTest < ActiveSupport::TestCase
  test "rejects voting for your own team" do
    ballot = Ballot.new(
      round_run: round_runs(:vote_solomon),
      team: teams(:leones),
      player: players(:lucia),
      choice_team: teams(:leones)
    )
    assert_not ballot.valid?
  end

  test "accepts a vote for another team" do
    assert ballots(:lucia_for_casa).valid?
    assert_equal teams(:casa).id, ballots(:lucia_for_casa).choice_team_id
  end
end
