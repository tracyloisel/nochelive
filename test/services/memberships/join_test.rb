require "test_helper"

class Memberships::JoinTest < ActiveSupport::TestCase
  test "joins only a snapshot team from the same Noche" do
    night = game_sessions(:elias)
    player = night.players.create!(name: "Nora", client_token: "nora", avatar_key: "delfin")
    team = teams(:lobby_leones)

    Memberships::Join.call(night:, player:, team:)
    assert_equal team, player.reload.team
    assert_equal team.ward_team, player.team.ward_team
  end

  test "rejects a team from another Noche" do
    night = game_sessions(:elias)
    player = night.players.create!(name: "Nora", client_token: "nora-2", avatar_key: "delfin")
    assert_raises(People::Error) { Memberships::Join.call(night:, player:, team: teams(:leones)) }
  end

  test "locks the team once the player has started a live quiz" do
    night = game_sessions(:david)
    player = players(:lucia)
    QuizRun.create!(device_digest: "team-lock", pack_id: "coronas", opened_at: Time.current, game_session: night, player:, team: player.team, live_sequence_position: 1)

    error = assert_raises(People::Error) do
      Memberships::Join.call(night:, player:, team: teams(:casa))
    end

    assert_equal I18n.t("nights.team_locked"), error.message
    assert_equal teams(:leones), player.reload.team
  end
end
