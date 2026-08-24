require "test_helper"

class TeamMembershipTest < ActiveSupport::TestCase
  test "player can only belong to one team" do
    membership = TeamMembership.new(player: players(:lucia), team: teams(:casa))
    assert_not membership.valid?
  end

  test "rejects a team from another night" do
    membership = TeamMembership.new(player: players(:lucia), team: teams(:lobby_leones))
    assert_not membership.valid?
    assert_includes membership.errors[:team], "must belong to the same night"
  end
end
