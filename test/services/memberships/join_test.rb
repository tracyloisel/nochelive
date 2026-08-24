require "test_helper"

class Memberships::JoinTest < ActiveSupport::TestCase
  test "remembers the season team on the ficha" do
    night = game_sessions(:elias)
    person = people(:pili)
    player = Players::Join.call(
      night:,
      name: person.given_name,
      role: "participant",
      location: "room",
      device_token: "pili-tablet",
      person:
    )
    team = Teams::Create.call(night:, name: "Leones de Judá", emblem: "leon")
    Memberships::Join.call(night:, player:, team:)
    assert_equal team, player.reload.team
    assert_equal team.ward_team, person.reload.last_ward_team
  end
end
