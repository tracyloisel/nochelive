require "test_helper"

class AnswersControllerTest < ActionDispatch::IntegrationTest
  setup { @night = game_sessions(:david) }

  test "buzzer answer after lock" do
    round = round_runs(:salomon)
    sign_in_as_participant(@night, name: "Sofía", team: teams(:leones))
    post night_round_run_buzz_path(@night.code, round)
    round.lock!
    post night_round_run_answer_path(@night.code, round), params: { choice: "wisdom" }
    assert_redirected_to night_play_path(@night.code)
    assert Answer.exists?(round_run: round, body: "wisdom")
  end

  test "true false auto scores" do
    round = round_runs(:rey_o_profeta)
    round.update!(phase: "open")
    sign_in_as_participant(@night, name: "Sofía", team: teams(:casa))
    post night_round_run_answer_path(@night.code, round), params: { choice: "false" }
    assert teams(:casa).reload.score_events.where(kind: "correct", round_run: round).exists?

    miss = round_runs(:elias_carmel)
    miss.update!(phase: "open")
    post night_round_run_answer_path(@night.code, miss), params: { choice: "wrong" }
    assert teams(:casa).reload.score_events.where(kind: "incorrect", round_run: miss).exists?
  end

  test "choice answer returns quiz bars as turbo stream" do
    round = round_runs(:rey_o_profeta)
    round.update!(phase: "open")
    sign_in_as_participant(@night, name: "Sofía", team: teams(:casa))
    post night_round_run_answer_path(@night.code, round), params: { choice: "false" }, as: :turbo_stream
    assert_response :success
    assert_match "quiz-bar", response.body
    assert_match "Siguiente", response.body
    assert_match "¡Correcto!", response.body
  end

  test "taboo miss does not auto score" do
    round = round_runs(:taboo_nabot)
    round.update!(phase: "open")
    sign_in_as_participant(@night, name: "Sofía", location: "remote")
    post night_round_run_answer_path(@night.code, round), params: { body: "Daniel" }
    assert_not seat_of(@night, "Sofía").score_events.where(kind: "correct", round_run: round).exists?
  end

  test "taboo match auto scores" do
    round = round_runs(:taboo_nabot)
    round.update!(phase: "open")
    sign_in_as_participant(@night, name: "Pablo", location: "remote")
    post night_round_run_answer_path(@night.code, round), params: { body: "Nabot" }
    assert seat_of(@night, "Pablo").score_events.where(kind: "correct", round_run: round).exists?
  end

  test "remote mime auto scores the story path" do
    round = round_runs(:mime_jonah)
    round.update!(phase: "open")
    sign_in_as_participant(@night, name: "Sofía", location: "remote")
    post night_round_run_answer_path(@night.code, round), params: { body: "storm,fish,shore" }
    assert seat_of(@night, "Sofía").score_events.where(kind: "correct", round_run: round).exists?
  end

  test "ordering auto scores the sequence" do
    round = round_runs(:kings_order)
    round.update!(phase: "open")
    sign_in_as_participant(@night, name: "Sofía", team: teams(:casa))
    post night_round_run_answer_path(@night.code, round), params: { body: "saul,david,salomon" }
    assert teams(:casa).reload.score_events.where(kind: "correct", round_run: round).exists?

    remote = open_session
    remote.post night_players_path(@night.code), params: { name: "Pablo", location: "remote" }
    remote.post night_round_run_answer_path(@night.code, round), params: { body: "salomon,david,saul" }
    assert seat_of(@night, "Pablo").score_events.where(kind: "incorrect", round_run: round).exists?
  end

  test "remote category auto scores three names" do
    round = round_runs(:category_prophets)
    round.update!(phase: "open")
    sign_in_as_participant(@night, name: "Sofía", location: "remote")
    post night_round_run_answer_path(@night.code, round), params: { body: "Jonás, Samuel, Moisés" }
    assert seat_of(@night, "Sofía").score_events.where(kind: "correct", round_run: round).exists?
  end

  test "remote answers a chapel buzzer as QCM" do
    round = round_runs(:salomon)
    sign_in_as_participant(@night, name: "Sofía", location: "remote")
    post night_round_run_answer_path(@night.code, round), params: { choice: "wisdom" }
    home = seat_of(@night, "Sofía")
    assert Answer.exists?(round_run: round, team: home, body: "wisdom")
    assert home.score_events.where(kind: "correct", round_run: round).exists?
    assert_not Buzz.exists?(round_run: round, team: home)
  end

  test "closed answer redirects" do
    round = round_runs(:salomon)
    round.reveal!
    sign_in_as_participant(@night, name: "Sofía", team: teams(:leones))
    post night_round_run_answer_path(@night.code, round), params: { body: "X" }
    assert_redirected_to night_play_path(@night.code)
  end
end
