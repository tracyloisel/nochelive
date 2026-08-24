require "test_helper"

class Ranks::AdvanceTest < ActiveSupport::TestCase
  test "crossing a rank grants Rey for the next correct" do
    team = teams(:casa)
    ScoreEvent.award!(game_session: game_sessions(:david), team: team, kind: "adjust", points: 0, xp: 30, reason: "prueba")
    team.reload
    assert_equal "explorador", team.rank_key
    assert_equal "Explorador", team.pending_rank_up
    assert team.next_correct_doubled?
    assert team.ready_chest.present?
  end

  test "staying on the same rank does not grant Rey" do
    team = teams(:casa)
    ScoreEvent.award!(game_session: game_sessions(:david), team: team, kind: "adjust", points: 0, xp: 10, reason: "poca")
    team.reload
    assert_equal "novicio", team.rank_key
    assert_nil team.pending_rank_up
    assert_not team.next_correct_doubled?
  end
end
