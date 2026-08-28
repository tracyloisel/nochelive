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

  test "choice answers are graded only at the shared reveal" do
    round = round_runs(:salomon)
    team = teams(:daniel_home)

    Answers::Submit.call(round:, team:, player: players(:daniel), body: "wisdom")
    assert_not team.score_events.where(round_run: round).exists?

    Rounds::Reveal.call(round:)

    assert team.reload.score_events.where(round_run: round, kind: "correct").exists?
  end
end
