require "test_helper"

class PlayAndWatchControllerTest < ActionDispatch::IntegrationTest
  setup { @night = game_sessions(:david) }

  test "play requires a player" do
    get night_play_path(@night.code)
    assert_redirected_to night_name_path(@night.code)
  end

  test "play shows the night for a teammate" do
    sign_in_as_participant(@night, name: "Sofía", team: teams(:leones))
    get night_play_path(@night.code)
    assert_response :success
  end

  test "open buzzer is a phone reel with the question illustration" do
    sign_in_as_participant(@night, name: "Sofía", team: teams(:leones))
    get night_play_path(@night.code)
    assert_response :success
    assert_select "body.is-kid.is-play"
    assert_select ".play-reel"
    assert_select ".play-shot"
    assert_select ".play-sheet[data-controller=sheet]"
    assert_select ".play-sheet-grip"
    assert_select ".story-close"
    assert_select ".play-reel[data-controller=story]"
    assert_select ".story-ticks"
    assert_select ".story-night", text: /Reyes y Profetas/
    assert_select ".story-audience", text: /En directo/
    assert_select ".story-audience .live-mark", text: "LIVE"
    assert_select ".story-audience .picto-eye"
    assert_select ".story-audience strong", text: /\d+/
    assert_select ".story-score", text: /\d+/
    assert_select ".story-meta .story-pills"
    assert_select ".story-meta .story-score"
    assert_select ".score-pop .team-bar"
    assert_select ".play-chrome > .team-bar", count: 0
    assert_select ".play-timer"
    assert_select ".play-timer-bar"
    assert_select ".buzz", text: /Buzz/
    assert_select ".prompt", text: /pidió|Salomón/
    assert_select ".play-round > .art", count: 0
    assert_select ".challenge-story[src='/media/stories/salomon_wisdom.jpg']"
    assert_select "[data-controller=slideshow]", count: 0
  end

  test "choice verdict shows bars and siguiente without waiting" do
    round_runs(:salomon).update_columns(phase: "completed")
    round = round_runs(:rey_o_profeta)
    round.update_columns(phase: "open", opened_at: Time.current)
    sign_in_as_participant(@night, name: "Sofía", team: teams(:casa))
    post night_round_run_answer_path(@night.code, round), params: { choice: "false" }
    get night_play_path(@night.code)
    assert_select ".quiz-board"
    assert_select ".quiz-verdict", text: /¡Correcto!/
    assert_select ".quiz-bar", count: 2
    assert_select ".quiz-next", text: /Siguiente/
    assert_select ".quiz-answer", text: /Elías fue profeta/
    assert_select ".reveal", count: 0
    assert_select ".wait", count: 0
    assert_select ".play-reel.is-quiz"

    round.update_columns(phase: "revealed", revealed_at: Time.current)
    get night_play_path(@night.code)
    assert_select ".quiz-board"
    assert_select ".quiz-bar"
    assert_select ".reveal", count: 0
    assert_select ".wait-toy", count: 0
  end

  test "watch creates a spectator" do
    assert_difference -> { @night.players.where(role: "spectator").count }, 1 do
      get night_watch_path(@night.code)
    end
    assert_response :success
  end
end
