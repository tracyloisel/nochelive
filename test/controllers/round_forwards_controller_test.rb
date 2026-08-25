require "test_helper"

class RoundForwardsControllerTest < ActionDispatch::IntegrationTest
  setup { @night = game_sessions(:david) }

  test "siguiente opens the next quiz round" do
    round_runs(:salomon).update!(phase: "completed")
    round = round_runs(:rey_o_profeta)
    round.update!(phase: "open", opened_at: Time.current)
    sign_in_as_participant(@night, name: "Sofía", team: teams(:casa))
    post night_round_run_answer_path(@night.code, round), params: { choice: "false" }
    post night_round_run_forward_path(@night.code, round)
    assert_redirected_to night_play_path(@night.code)
    assert round.reload.completed?
    assert round_runs(:david_goliath).reload.open?
  end

  test "siguiente turbo stream replaces the play frame" do
    round_runs(:salomon).update!(phase: "completed")
    round = round_runs(:rey_o_profeta)
    round.update!(phase: "open", opened_at: Time.current)
    sign_in_as_participant(@night, name: "Sofía", team: teams(:casa))
    post night_round_run_answer_path(@night.code, round), params: { choice: "false" }
    post night_round_run_forward_path(@night.code, round), as: :turbo_stream
    assert_response :success
    assert_match "night_play", response.body
  end
end
