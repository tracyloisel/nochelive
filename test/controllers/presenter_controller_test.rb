require "test_helper"

class PresenterControllersTest < ActionDispatch::IntegrationTest
  setup do
    @night = game_sessions(:david)
    @round = round_runs(:salomon)
  end

  test "gate requires token then remembers presenter" do
    get presenter_console_path(@night.code)
    assert_redirected_to presenter_gate_path(@night.code)

    get presenter_gate_path(@night.code)
    assert_response :success

    post presenter_gate_path(@night.code), params: { token: "nope" }
    assert_redirected_to presenter_gate_path(@night.code)

    get presenter_gate_path(@night.code, token: "presenter-secret")
    assert_redirected_to presenter_console_path(@night.code)
    get presenter_console_path(@night.code)
    assert_response :success

    post presenter_gate_path(@night.code), params: { token: "presenter-secret" }
    assert_redirected_to presenter_console_path(@night.code)
  end

  test "already-authenticated gate redirects to console" do
    sign_in_presenter(@night)
    get presenter_gate_path(@night.code)
    assert_redirected_to presenter_console_path(@night.code)
  end

  test "start pause resume finish" do
    night = game_sessions(:elias)
    sign_in_presenter(night)
    post presenter_start_path(night.code)
    assert night.reload.playing?
    post presenter_pause_path(night.code)
    assert night.reload.paused?
    post presenter_resume_path(night.code)
    assert night.reload.playing?
    post presenter_finish_path(night.code)
    assert night.reload.finished?
  end

  test "open lock reveal complete" do
    sign_in_presenter(@night)
    pending = round_runs(:rey_o_profeta)
    post presenter_open_round_path(@night.code, pending)
    assert_equal "open", pending.reload.phase

    post presenter_lock_round_path(@night.code, pending)
    assert pending.reload.locked?

    post presenter_reveal_round_path(@night.code, pending)
    assert pending.reload.revealed?

    post presenter_complete_round_path(@night.code, pending)
    assert pending.reload.completed?
    assert_equal "intro", round_runs(:david_goliath).reload.phase
  end

  test "crown on the finale finishes the night" do
    sign_in_presenter(@night)
    @night.update!(status: "playing")
    round = round_runs(:finale_prophet)
    @night.round_runs.where.not(id: round.id).update_all(phase: "completed")
    round.update!(phase: "open", opened_at: Time.current)
    post presenter_crown_path(@night.code, round)
    assert_redirected_to presenter_console_path(@night.code)
    assert @night.reload.finished?
    get presenter_console_path(@night.code)
    assert_includes response.body, "¡TODOS DE PIE!"
    assert_not_includes response.body, "Siguiente"
  end

  test "completing the last round finishes the night" do
    sign_in_presenter(@night)
    @round.update_column(:position, 99)
    post presenter_complete_round_path(@night.code, @round)
    assert @night.reload.finished?
  end

  test "presenter scores" do
    sign_in_presenter(@night)
    team = teams(:casa)
    post presenter_scores_path(@night.code), params: { team_id: team.id, round_run_id: @round.id, kind: "correct" }
    assert team.reload.score_events.where(kind: "correct", round_run: @round).exists?

    other = round_runs(:rey_o_profeta)
    other.update!(phase: "open")
    post presenter_scores_path(@night.code), params: { team_id: team.id, round_run_id: other.id, kind: "incorrect" }
    assert team.score_events.where(kind: "incorrect", round_run: other).exists?

    post presenter_scores_path(@night.code), params: { team_id: team.id, kind: "plus" }
    post presenter_scores_path(@night.code), params: { team_id: team.id, kind: "minus" }
    assert team.score_events.where(kind: "adjust", points: 5).exists?
    assert team.score_events.where(kind: "adjust", points: -5).exists?
  end
end
