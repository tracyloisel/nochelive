require "test_helper"

class TeamTest < ActiveSupport::TestCase
  test "fixture labels and progress" do
    leones = teams(:leones)
    assert_equal "León", leones.emblem_label
    assert_equal "Novicio", leones.rank_label
    assert_equal "Explorador", leones.next_rank_label
    assert_operator leones.xp_progress, :>=, 0
    assert_equal reward_grants(:salomon_chest), leones.ready_chest
  end

  test "recalculate unlocks the chest and can double the next correct" do
    team = teams(:casa)
    ScoreEvent.award!(game_session: game_sessions(:david), team: team, kind: "adjust", points: 0, xp: 30, reason: "prueba")
    team.reload
    assert_equal "explorador", team.rank_key
    assert_equal "Explorador", team.pending_rank_up
    assert team.rey?
    assert team.ready_chest.present?
  end
end
