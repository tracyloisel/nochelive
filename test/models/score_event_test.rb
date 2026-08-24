require "test_helper"

class ScoreEventTest < ActiveSupport::TestCase
  test "correct answer grants points xp rank and does not duplicate" do
    night = create_night
    team = add_team(night, name: "Leones")
    round = night.round_runs.first
    round.intro!
    round.open!

    ScoreApplier.correct!(round, team)
    team.reload
    assert_operator team.cached_score, :>=, 10
    assert_operator team.xp, :>=, 20
    assert_equal 1, team.streak
    assert team.ready_chest.present?

    ScoreApplier.correct!(round, team)
    assert_equal 1, team.score_events.where(kind: "correct").count
  end

  test "xp bar moves toward the next rank" do
    night = create_night
    team = add_team(night, name: "Leones")
    assert_equal "Novicio", team.rank_label
    ScoreEvent.award!(game_session: night, team: team, kind: "adjust", points: 0, xp: 20, reason: "prueba")
    team.reload
    assert_operator team.xp_progress, :>, 0
    assert_equal "Explorador", team.next_rank_label
  end

  test "crossing a rank is a pending event the team must acknowledge" do
    night = create_night
    team = add_team(night, name: "Leones")
    ScoreEvent.award!(game_session: night, team: team, kind: "adjust", points: 0, xp: 30, reason: "prueba")
    team.reload
    assert_equal "Explorador", team.pending_rank_up
    assert_equal "explorador", team.rank_key
    assert team.rey?
    Ranks::Acknowledge.call(team:)
    assert_nil team.reload.pending_rank_up
    assert team.rey?
    assert_equal "Explorador", team.rank_label
  end

  test "opening a chest is a one-shot event" do
    night = create_night
    team = add_team(night, name: "Leones")
    grant = team.reward_grants.create!(chest_key: "cofre_salomon", state: "ready")
    grant.open!
    assert grant.opened?
    assert_includes RewardGrant::REWARDS.keys, grant.reward_key
    assert_raises(RuntimeError) { grant.open! }
  end

  test "each chest reward applies" do
    %w[corona fuego escudo sabiduria].each do |key|
      night = create_night
      team = add_team(night, name: "C#{key}")
      grant = team.reward_grants.create!(chest_key: "cofre_salomon", state: "ready")
      grant.send(:apply_reward!, key)
      team.reload
      case key
      when "corona"
        assert team.next_correct_doubled?
      when "fuego"
        assert_equal 8, team.score_events.find_by!(kind: "chest").points
      when "escudo"
        assert_equal 5, team.score_events.find_by!(kind: "chest").points
      when "sabiduria"
        assert_equal 6, team.score_events.find_by!(kind: "chest").points
      end
    end
  end
end
