require "test_helper"

class ChestsAndRankUpsControllerTest < ActionDispatch::IntegrationTest
  setup { @night = game_sessions(:david) }

  test "open a ready chest" do
    sign_in_as_participant(@night, name: "Sofía", team: teams(:leones))
    post night_chest_path(@night.code, reward_grants(:salomon_chest))
    assert_redirected_to night_play_path(@night.code)
    assert reward_grants(:salomon_chest).reload.opened?
  end

  test "opening twice still redirects" do
    grant = reward_grants(:salomon_chest)
    grant.open!
    sign_in_as_participant(@night, name: "Sofía", team: teams(:leones))
    post night_chest_path(@night.code, grant)
    assert_redirected_to night_play_path(@night.code)
  end

  test "acknowledge rank up" do
    teams(:leones).update!(pending_rank_up: "Explorador", next_correct_doubled: true)
    sign_in_as_participant(@night, name: "Sofía", team: teams(:leones))
    post night_rank_up_path(@night.code)
    assert_redirected_to night_play_path(@night.code)
    leones = teams(:leones).reload
    assert_nil leones.pending_rank_up
    assert leones.rey?
  end
end
