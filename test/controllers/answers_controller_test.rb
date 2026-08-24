require "test_helper"

class AnswersControllerTest < ActionDispatch::IntegrationTest
  setup { @night = game_sessions(:david) }

  test "buzzer answer after lock" do
    round = round_runs(:salomon)
    sign_in_as_participant(@night, name: "Sofía", team: teams(:leones))
    post night_round_run_buzz_path(@night.code, round)
    round.lock!
    post night_round_run_answer_path(@night.code, round), params: { body: "Sabiduría" }
    assert_redirected_to night_play_path(@night.code)
    assert Answer.exists?(round_run: round, body: "Sabiduría")
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

  test "taboo miss does not auto score" do
    round = round_runs(:taboo_nabot)
    round.update!(phase: "open")
    sign_in_as_participant(@night, name: "Sofía", location: "remote", team: teams(:casa))
    post night_round_run_answer_path(@night.code, round), params: { body: "Daniel" }
    assert_not teams(:casa).reload.score_events.where(kind: "correct", round_run: round).exists?
  end

  test "taboo match auto scores" do
    round = round_runs(:taboo_nabot)
    round.update!(phase: "open")
    sign_in_as_participant(@night, name: "Pablo", location: "remote", team: teams(:leones))
    post night_round_run_answer_path(@night.code, round), params: { body: "Nabot" }
    assert teams(:leones).reload.score_events.where(kind: "correct", round_run: round).exists?
  end

  test "remote mime auto scores the story path" do
    round = round_runs(:mime_jonah)
    round.update!(phase: "open")
    sign_in_as_participant(@night, name: "Sofía", location: "remote", team: teams(:casa))
    post night_round_run_answer_path(@night.code, round), params: { body: "storm,fish,shore" }
    assert teams(:casa).reload.score_events.where(kind: "correct", round_run: round).exists?
  end

  test "ordering auto scores the sequence" do
    round = round_runs(:kings_order)
    round.update!(phase: "open")
    sign_in_as_participant(@night, name: "Sofía", team: teams(:casa))
    post night_round_run_answer_path(@night.code, round), params: { body: "saul,david,salomon" }
    assert teams(:casa).reload.score_events.where(kind: "correct", round_run: round).exists?

    sign_in_as_participant(@night, name: "Pablo", location: "remote", team: teams(:leones))
    post night_round_run_answer_path(@night.code, round), params: { body: "salomon,david,saul" }
    assert teams(:leones).reload.score_events.where(kind: "incorrect", round_run: round).exists?
  end

  test "remote category auto scores three names" do
    round = round_runs(:category_prophets)
    round.update!(phase: "open")
    sign_in_as_participant(@night, name: "Sofía", location: "remote", team: teams(:casa))
    post night_round_run_answer_path(@night.code, round), params: { body: "Jonás, Samuel, Moisés" }
    assert teams(:casa).reload.score_events.where(kind: "correct", round_run: round).exists?
  end

  test "closed answer redirects" do
    round = round_runs(:salomon)
    round.reveal!
    sign_in_as_participant(@night, name: "Sofía", team: teams(:leones))
    post night_round_run_answer_path(@night.code, round), params: { body: "X" }
    assert_redirected_to night_play_path(@night.code)
  end
end
