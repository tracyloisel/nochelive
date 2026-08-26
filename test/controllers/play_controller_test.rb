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
    round_runs(:salomon).update_column(:opened_at, Time.current)
    sign_in_as_participant(@night, name: "Sofía", team: teams(:leones))
    get night_play_path(@night.code)
    assert_response :success
    assert_select "body.is-kid.is-play"
    assert_select ".play-reel"
    assert_select ".play-round.is-night-live"
    assert_select ".night-quiz-head"
    assert_select ".street-quiz-lockup-name", text: "Noche Live"
    assert_select ".play-shot"
    assert_select ".play-sheet[data-controller=sheet]"
    assert_select ".play-sheet-grip"
    assert_select ".story-close"
    assert_select ".play-reel[data-controller=story]"
    assert_select ".night-quiz-head .story-ticks"
    assert_select ".story-night", text: /Reyes y Profetas/
    assert_select ".story-audience", count: 0
    assert_select ".live-mark", count: 0
    assert_select ".story-score", text: /\d+/
    assert_select ".story-meta .story-score"
    assert_select ".score-pop .team-bar"
    assert_select ".play-chrome > .team-bar", count: 0
    assert_select ".play-timer"
    assert_select ".play-timer-bar"
    assert_select ".play-timer.is-warn", count: 0
    assert_select ".play-timer.is-low", count: 0
    assert_select "#night_play[data-stage-bed-value=timer_tension]"
    assert_select "#night_play[data-stage-timer-end-value]"
    assert_select "#night_play[data-stage-timer-duration-value=?]", "30"
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
    assert_select ".quiz-bar .quiz-meta .quiz-pct"
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
    round_runs(:salomon).update_column(:opened_at, Time.current)
    assert_difference -> { @night.players.where(role: "spectator").count }, 1 do
      get night_watch_path(@night.code)
    end
    assert_response :success
    assert_select "#night_watch[data-stage-bed-value=timer_tension]"
    assert_select "#night_watch[data-stage-timer-end-value]"
    assert_select "#night_watch[data-stage-timer-duration-value=?]", "30"
  end

  test "remote play shows the QCM without a buzz" do
    sign_in_as_participant(@night, name: "Sofía", location: "remote")
    get night_play_path(@night.code)
    assert_response :success
    assert_select ".choice-btn"
    assert_select ".buzz", count: 0
    assert_select ".quiz-board"
    assert_select ".score-pop h1", text: "Sofía"
    assert_select ".play-reel.is-quiz"
  end

  test "twenty-second night ask does not start in the warn zone" do
    freeze_time
    round_runs(:salomon).update_columns(phase: "completed")
    round_runs(:rey_o_profeta).update_columns(phase: "open", opened_at: Time.current)
    sign_in_as_participant(@night, name: "Sofía", team: teams(:leones))
    get night_play_path(@night.code)
    assert_select ".play-timer"
    assert_select ".play-timer.is-warn", count: 0
    assert_select ".play-timer.is-low", count: 0
    assert_select "#night_play[data-stage-timer-duration-value=?]", "20"

    travel 12.seconds
    get night_play_path(@night.code)
    assert_select ".play-timer.is-warn"

    travel 4.seconds
    get night_play_path(@night.code)
    assert_select ".play-timer.is-low"
  end

  test "pick team is a reel" do
    sign_in_as_participant(@night, name: "Sofía")
    get night_play_path(@night.code)
    assert_select ".play-reel.is-pick"
    assert_select ".play-shot .challenge-story"
    assert_select ".play-sheet h1", text: /Elige tu equipo/
    assert_select ".play-chrome > .team-bar", count: 0
    assert_select ".picto-btn", count: 0
  end

  test "lobby is a reel" do
    lobby = game_sessions(:elias)
    sign_in_as_participant(lobby, name: "Nora", team: teams(:lobby_leones))
    get night_play_path(lobby.code)
    assert_select ".play-reel.is-lobby.is-night-live"
    assert_select ".night-quiz-head"
    assert_select ".play-sheet", text: /Esperad/
    assert_select ".play-shot .challenge-story"
    assert_select ".lobby-wait"
    assert_select ".play-shot-seat"
    assert_select ".story-score"
    assert_select ".wait-dots", count: 0
    assert_select ".story-ticks", count: 0
    assert_select ".street-quiz-lockup-tag", count: 0
    assert_select ".picto-btn", count: 0
  end

  test "rank-up is a reel" do
    teams(:leones).update!(pending_rank_up: "Explorador", next_correct_doubled: true)
    sign_in_as_participant(@night, name: "Pilar", team: teams(:leones))
    get night_play_path(@night.code)
    assert_select ".play-reel.is-rank"
    assert_select ".play-sheet", text: /Nueva dignidad/
    assert_select ".play-shot .challenge-story"
    assert_select ".picto-btn", count: 0
  end

  test "finished night ceremony is a reel" do
    done = game_sessions(:cerrada)
    sign_in_as_participant(done, name: "Rita", team: teams(:campeones))
    get night_play_path(done.code)
    assert_select ".play-reel.is-finale"
    assert_select ".play-sheet[data-sheet-snap=mid] .ceremony", text: /gana la noche/
    assert_select ".play-shot .challenge-story"
    assert_select ".play-chrome > .team-bar", count: 0
  end
end
