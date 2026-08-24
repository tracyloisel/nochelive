require "test_helper"

class WardTeamTest < ActiveSupport::TestCase
  test "season thresholds are four times the night ranks" do
    assert_equal 100, WardTeam::SEASON_RANKS[1][0]
    assert_equal "Novicio", ward_teams(:leones_season).season_rank_label
  end
end
