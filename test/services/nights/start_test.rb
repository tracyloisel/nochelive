require "test_helper"

class Nights::StartTest < ActiveSupport::TestCase
  test "opens a night inside a rama and clones season teams" do
    night = Nights::Start.call(ward: wards(:demo))
    assert_equal wards(:demo), night.ward
    assert_equal 15, night.round_runs.count
    assert_equal [ "Casa de David", "Leones de Judá" ], night.teams.order(:name).pluck(:name)
    assert night.teams.all? { |team| team.xp.zero? }
    assert_equal ward_teams(:leones_season), night.teams.find_by!(name: "Leones de Judá").ward_team
  end
end
