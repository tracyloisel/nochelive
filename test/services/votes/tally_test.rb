require "test_helper"

class Votes::TallyTest < ActiveSupport::TestCase
  test "awards the team with more ballots" do
    round = round_runs(:vote_solomon)
    Ballot.delete_all
    TeamMembership.create!(player: players(:ana), team: teams(:leones))
    Ballot.create!(round_run: round, team: teams(:leones), player: players(:lucia), choice_team: teams(:casa))
    Ballot.create!(round_run: round, team: teams(:leones), player: players(:ana), choice_team: teams(:casa))
    Ballot.create!(round_run: round, team: teams(:daniel_home), player: players(:daniel), choice_team: teams(:leones))

    Votes::Tally.call(round:)

    assert teams(:casa).reload.score_events.where(kind: "correct", round_run: round).exists?
    assert_not teams(:leones).reload.score_events.where(kind: "correct", round_run: round).exists?
  end

  test "does nothing without ballots" do
    night = game_sessions(:david)
    round = round_runs(:salomon)
    assert_nothing_raised { Votes::Tally.call(round:) }
    assert_not night.score_events.where(round_run: round, kind: "correct").exists?
  end
end
