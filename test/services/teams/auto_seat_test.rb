require "test_helper"

class Teams::AutoSeatTest < ActiveSupport::TestCase
  test "uses the returning participant's ward team" do
    night = game_sessions(:david)
    person = people(:carmen_lopez)
    person.update!(last_ward_team: ward_teams(:casa_season))
    player = night.players.create!(
      person:,
      name: person.given_name,
      role: "participant",
      location: "room",
      client_token: SecureRandom.uuid,
      avatar_key: person.avatar_key
    )

    team = Teams::AutoSeat.call(night:, player:)

    assert_equal teams(:casa), team
    assert_equal team, player.reload.team
  end

  test "balances a guest into the smallest chapel team" do
    night = game_sessions(:david)
    player = night.players.create!(
      name: "Invitée",
      role: "participant",
      location: "room",
      client_token: SecureRandom.uuid,
      avatar_key: "delfin"
    )

    team = Teams::AutoSeat.call(night:, player:)

    assert team.chapel?
    assert_equal team, player.reload.team
  end
end
