require "test_helper"

class PresenterControllersTest < ActionDispatch::IntegrationTest
  setup do
    @night = game_sessions(:david)
    @round = round_runs(:salomon)
  end

  test "gate is a claim, not a secret" do
    get presenter_console_path(@night.code)
    assert_redirected_to presenter_gate_path(@night.code)

    get presenter_gate_path(@night.code)
    assert_response :success
    assert_select "h1", text: /presentador/i
    assert_select "form[action=?]", presenter_claim_path(@night.code)
    assert_select "button", text: /Soy el presentador/
    assert_select "#ward_token", count: 0
    assert_select "#token", count: 0

    post presenter_gate_path(@night.code), params: { token: "nope" }
    assert_redirected_to presenter_gate_path(@night.code)

    get presenter_gate_path(@night.code, token: "presenter-secret")
    assert_redirected_to presenter_console_path(@night.code)
    get presenter_console_path(@night.code)
    assert_response :success

    post presenter_gate_path(@night.code), params: { token: "presenter-secret" }
    assert_redirected_to presenter_console_path(@night.code)
  end

  test "anyone can take an empty desk" do
    post presenter_claim_path(@night.code)
    assert_redirected_to presenter_console_path(@night.code)
    get presenter_console_path(@night.code)
    assert_response :success
    assert_select ".claim-modal", count: 0
  end

  test "claiming a held desk waits and asks the holder" do
    holder = open_session
    holder.get presenter_gate_path(@night.code, token: "presenter-secret")
    holder.follow_redirect!

    claimant = open_session
    claimant.post presenter_claim_path(@night.code)
    claimant.assert_redirected_to presenter_claim_path(@night.code)
    claimant.follow_redirect!
    claimant.assert_response :success
    assert_includes claimant.response.body, "Le avisamos a quien tiene la mesa"
    assert_includes claimant.response.body, "un minuto es tuya"

    holder.get presenter_console_path(@night.code)
    assert_includes holder.response.body, "¿Ceder la consola?"
    assert_includes holder.response.body, "Alguien"
    assert_includes holder.response.body, "Ceder la mesa"
    assert_includes holder.response.body, "Seguir yo"
    assert_includes holder.response.body, "Nunca esta persona"
  end

  test "a named player is shown on the holder modal" do
    holder = open_session
    holder.get presenter_gate_path(@night.code, token: "presenter-secret")
    holder.follow_redirect!

    claimant = open_session
    claimant.post night_players_path(@night.code), params: { name: "Lucía", location: "room" }
    claimant.post presenter_claim_path(@night.code)
    holder.get presenter_console_path(@night.code)
    assert_includes holder.response.body, "Lucía quiere presentar"
  end

  test "silent holder cedes after a minute" do
    holder = open_session
    holder.get presenter_gate_path(@night.code, token: "presenter-secret")
    holder.follow_redirect!

    claimant = open_session
    claimant.post presenter_claim_path(@night.code)
    claimant.follow_redirect!

    travel PresenterClaim::TIMEOUT.seconds + 1
    holder.get presenter_console_path(@night.code)
    holder.assert_redirected_to presenter_gate_path(@night.code)

    claimant.get presenter_claim_path(@night.code)
    claimant.assert_redirected_to presenter_console_path(@night.code)
    claimant.follow_redirect!
    claimant.assert_response :success
  end

  test "holder can refuse then block that phone" do
    holder = open_session
    holder.get presenter_gate_path(@night.code, token: "presenter-secret")
    holder.follow_redirect!

    claimant = open_session
    claimant.post presenter_claim_path(@night.code)
    claim = PresenterClaim.pending.last

    holder.post presenter_claim_resolve_path(@night.code, claim), params: { decision: "refuse" }
    holder.assert_redirected_to presenter_console_path(@night.code)
    claimant.get presenter_claim_path(@night.code)
    assert_includes claimant.response.body, "El presentador sigue en la mesa"

    claimant.post presenter_claim_path(@night.code)
    claim = PresenterClaim.pending.last
    holder.post presenter_claim_resolve_path(@night.code, claim), params: { decision: "block" }
    claimant.get presenter_claim_path(@night.code)
    assert_includes claimant.response.body, "Esta noche no te deja presentar"
    claimant.post presenter_claim_path(@night.code)
    claimant.assert_redirected_to presenter_gate_path(@night.code)
    claimant.follow_redirect!
    assert_includes claimant.response.body, "no te deja"
  end

  test "holder can cede at once" do
    holder = open_session
    holder.get presenter_gate_path(@night.code, token: "presenter-secret")
    holder.follow_redirect!

    claimant = open_session
    claimant.post presenter_claim_path(@night.code)
    claim = PresenterClaim.pending.last

    holder.post presenter_claim_resolve_path(@night.code, claim), params: { decision: "grant" }
    holder.assert_redirected_to presenter_gate_path(@night.code)

    claimant.get presenter_claim_path(@night.code)
    claimant.assert_redirected_to presenter_console_path(@night.code)
  end

  test "claim wait without a petition returns to the gate" do
    get presenter_claim_path(@night.code)
    assert_redirected_to presenter_gate_path(@night.code)
  end

  test "resolve without the desk is sent to the gate" do
    post presenter_claim_resolve_path(@night.code, 0), params: { decision: "grant" }
    assert_redirected_to presenter_gate_path(@night.code)
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

  test "completing does not crash when the next round is already intro" do
    sign_in_presenter(@night)
    round_runs(:rey_o_profeta).update!(phase: "intro")
    post presenter_complete_round_path(@night.code, @round)
    assert_redirected_to presenter_console_path(@night.code)
    assert @round.reload.completed?
    assert_equal "intro", round_runs(:rey_o_profeta).reload.phase
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

  test "console is a live reel with the round as the title" do
    sign_in_presenter(@night)
    get presenter_console_path(@night.code)
    assert_response :success
    assert_select ".console.is-stage[data-controller=story]"
    assert_select ".story-close"
    assert_select ".story-ticks"
    assert_select ".code-chip", text: @night.code
    assert_select ".stage-ticks li"
    assert_select ".stage-shot"
    assert_select ".stage-dock"
    assert_select ".presence.is-stage"
    assert_select "h1", text: "La elección de Salomón"
    assert_select ".live", text: /En directo/
    assert_select ".challenge-story[src='/media/stories/salomon_wisdom.jpg']"
    assert_select "[data-controller=slideshow]", count: 0
    assert_includes response.body, "Cerrar buzzer"
    assert_select ".desk-sheet[data-controller~=sheet][data-controller~=desk]"
    assert_select ".desk-tabs"
    assert_select ".desk-tab", text: /Respuestas/
    assert_select ".desk-tab", text: "Marcador"
    assert_select ".desk-team", text: /Leones de Judá/
    assert_includes response.body, "Historial de puntos"
  end

  test "console desk grades choice answers with Spanish labels" do
    sign_in_presenter(@night)
    round_runs(:salomon).update!(phase: "completed")
    round = round_runs(:rey_o_profeta)
    round.update!(phase: "open", opened_at: Time.current)
    Answer.create!(round_run: round, team: teams(:leones), player: players(:lucia), body: "false")

    get presenter_console_path(@night.code)
    assert_response :success
    assert_select ".desk-answer .eyebrow", text: "Leones de Judá"
    assert_select ".desk-answer-body", text: "Falso"
    assert_select "button", text: "Correcta"
    assert_select "button", text: "Incorrecta"
  end

  test "graded console answers show a tick or a cross" do
    sign_in_presenter(@night)
    round_runs(:salomon).update!(phase: "completed")
    round = round_runs(:rey_o_profeta)
    round.update!(phase: "open", opened_at: Time.current)
    Answer.create!(round_run: round, team: teams(:leones), player: players(:lucia), body: "false")
    Answer.create!(round_run: round, team: teams(:casa), player: players(:daniel), body: "true")
    Scores::Apply.correct!(round, teams(:leones), broadcast: false)
    Scores::Apply.incorrect!(round, teams(:casa), broadcast: false)

    get presenter_console_path(@night.code)
    assert_response :success
    assert_select ".desk-answer.is-yes .picto-tick"
    assert_select ".desk-answer.is-no .picto-cross"
    assert_select ".desk-mark .word", text: "Correcta"
    assert_select ".desk-mark .word", text: "Incorrecta"
    assert_select ".desk-answer.is-yes button", text: "Incorrecta"
    assert_select ".desk-answer.is-no button", text: "Correcta"
  end

  test "presenter incorrect takes back points from a previous correct" do
    sign_in_presenter(@night)
    team = teams(:casa)
    post presenter_scores_path(@night.code), params: { team_id: team.id, round_run_id: @round.id, kind: "correct" }
    assert_operator team.reload.cached_score, :>, 0

    post presenter_scores_path(@night.code), params: { team_id: team.id, round_run_id: @round.id, kind: "incorrect" }
    team.reload
    assert_equal 0, team.cached_score
    assert_not team.score_events.where(kind: "correct", round_run: @round).exists?
    assert team.score_events.where(kind: "incorrect", round_run: @round).exists?
  end

  test "lobby reel starts the night from the dock" do
    night = game_sessions(:elias)
    sign_in_presenter(night)
    get presenter_console_path(night.code)
    assert_response :success
    assert_select ".console.is-stage"
    assert_select ".stage-dock"
    assert_includes response.body, "Empezar la noche"
    assert_includes response.body, "Abrir"
  end
end
