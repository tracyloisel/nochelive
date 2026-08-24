require "test_helper"

class WardTeams::RecordNightTest < ActiveSupport::TestCase
  test "adds night xp to the season once" do
    night = game_sessions(:david)
    team = teams(:leones)
    team.update!(xp: 30)
    night.update!(status: "playing", season_applied_at: nil)

    WardTeams::RecordNight.call(night:)
    season = ward_teams(:leones_season)
    assert_equal 30, season.reload.season_xp
    assert_equal "novicio", season.season_rank_key

    WardTeams::RecordNight.call(night: night.reload)
    assert_equal 30, season.reload.season_xp
  end

  test "season ranks use four times the night thresholds" do
    night = game_sessions(:david)
    teams(:leones).update!(xp: 100)
    night.update!(status: "playing", season_applied_at: nil)

    WardTeams::RecordNight.call(night:)
    season = ward_teams(:leones_season).reload
    assert_equal 100, season.season_xp
    assert_equal "explorador", season.season_rank_key
    assert_equal "Explorador", teams(:leones).reload.season_rank_up
  end
end
