require "test_helper"

class RoundForwardsControllerTest < ActionDispatch::IntegrationTest
  setup { @night = game_sessions(:david) }

  test "legacy siguiente never advances the shared round" do
    round_runs(:salomon).update!(phase: "completed")
    round = round_runs(:rey_o_profeta)
    round.update!(phase: "open", opened_at: Time.current)
    sign_in_as_participant(@night, name: "Sofía", team: teams(:casa))
    post night_round_run_answer_path(@night.code, round), params: { choice: "false" }
    post night_round_run_forward_path(@night.code, round)
    assert_redirected_to night_play_path(@night.code)
    assert round.reload.open?
    assert round_runs(:david_goliath).reload.pending?
  end

  test "legacy siguiente turbo stream is a no-op" do
    round_runs(:salomon).update!(phase: "completed")
    round = round_runs(:rey_o_profeta)
    round.update!(phase: "open", opened_at: Time.current)
    sign_in_as_participant(@night, name: "Sofía", team: teams(:casa))
    post night_round_run_answer_path(@night.code, round), params: { choice: "false" }
    post night_round_run_forward_path(@night.code, round), as: :turbo_stream
    assert_response :no_content
    assert round.reload.open?
  end
end
