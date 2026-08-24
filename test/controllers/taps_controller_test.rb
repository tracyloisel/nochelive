require "test_helper"

class TapsAndPoseHoldsControllerTest < ActionDispatch::IntegrationTest
  setup { @night = game_sessions(:david) }

  test "tap registers and rejects when closed" do
    round = round_runs(:david_goliath)
    round.update!(phase: "open")
    sign_in_as_participant(@night, name: "Sofía", team: teams(:leones))
    post night_round_run_tap_path(@night.code, round)
    assert_response :ok
    round.update!(phase: "locked")
    post night_round_run_tap_path(@night.code, round)
    assert_response :unprocessable_entity
  end

  test "pose hold completes at eight seconds" do
    round = round_runs(:statue_david)
    round.update!(phase: "open")
    sign_in_as_participant(@night, name: "Sofía", location: "remote", team: teams(:leones))
    post night_round_run_pose_hold_path(@night.code, round), params: { held_ms: 8500 }
    assert_response :ok
    assert PoseHold.find_by(round_run: round, team: teams(:leones)).finished?
    round.update!(phase: "locked")
    post night_round_run_pose_hold_path(@night.code, round), params: { held_ms: 9000 }
    assert_response :unprocessable_entity
  end
end
