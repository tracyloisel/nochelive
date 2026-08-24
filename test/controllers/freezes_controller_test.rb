require "test_helper"

class FreezesControllerTest < ActionDispatch::IntegrationTest
  setup { @night = game_sessions(:david) }

  test "remote catch after freeze scores" do
    round = round_runs(:freeze_saul)
    round.update!(phase: "open", opened_at: Time.current)
    sign_in_presenter(@night)
    post presenter_lock_round_path(@night.code, round)
    sign_in_as_participant(@night, name: "Sofía", location: "remote", team: teams(:casa))
    post night_round_run_freeze_path(@night.code, round)
    assert_redirected_to night_play_path(@night.code)
    assert teams(:casa).reload.score_events.where(kind: "correct", round_run: round).exists?
  end

  test "catch before freeze redirects" do
    round = round_runs(:freeze_saul)
    round.update!(phase: "open", opened_at: Time.current)
    sign_in_as_participant(@night, name: "Sofía", location: "remote", team: teams(:casa))
    post night_round_run_freeze_path(@night.code, round)
    assert_redirected_to night_play_path(@night.code)
    assert_not teams(:casa).reload.score_events.where(round_run: round).exists?
  end
end
