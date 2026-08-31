require "test_helper"

class WardTeamTest < ActiveSupport::TestCase
  test "persistent teams are unique within their ward" do
    duplicate = WardTeam.new(
      ward: ward_teams(:leones_ward_team).ward,
      name: ward_teams(:leones_ward_team).name,
      emblem: "paloma"
    )

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:name, :taken)
  end
end
