require "test_helper"

class LivePresenceTest < ActionDispatch::IntegrationTest
  setup { @night = game_sessions(:david) }

  test "watch shows a single scoreboard strip" do
    players(:lucia).update_column(:last_seen_at, Time.current)
    players(:daniel).update_column(:last_seen_at, Time.current)
    get night_watch_path(@night.code)
    assert_response :success
    assert_select ".watch-board .score-strip"
    assert_select ".watch-board .score-strip .emblem"
    assert_select ".watch-chrome .watch-wordmark", text: /Noche Live/
    assert_select ".presence-stat", count: 0
    assert_select ".story-audience", count: 0
    assert_select "#live_pulses"
  end

  test "empty watch HUD waits for people in the caption" do
    night = create_night
    get night_watch_path(night.code)
    assert_response :success
    assert_select ".watch-caption", text: /equipos se reúnen/
    assert_select ".presence-wait", count: 0
  end

  test "play reel shows a score button without a LIVE costume" do
    sign_in_as_participant(@night, name: "Sofía", team: teams(:leones))
    get night_play_path(@night.code)
    assert_response :success
    assert_select ".story-audience", count: 0
    assert_select ".live-mark", count: 0
    assert_select ".story-score"
    assert_select ".play-chrome > .team-bar", count: 0
    assert_select "#night_presence"
    assert_select ".presence-team .presence-face"
    assert_select "[data-controller=presence]"
  end

  test "join scavenger and category pulses use distinct pictures" do
    html = ApplicationController.render(partial: "shared/pulse", locals: { pulse: { kind: "join", player: players(:lucia) } })
    assert_includes html, "picto-person"
    assert_includes html, "data-sfx=\"chest\""
    html = ApplicationController.render(partial: "shared/pulse", locals: { pulse: { kind: "found", player: players(:lucia) } })
    assert_includes html, "picto-found"
    assert_includes html, "data-sfx=\"buzzer_hit\""
    html = ApplicationController.render(partial: "shared/pulse", locals: { pulse: { kind: "shout", player: players(:lucia) } })
    assert_includes html, "picto-speak"
  end

  test "buzz pulse shows recorded delay" do
    html = ApplicationController.render(
      partial: "shared/pulse",
      locals: { pulse: { kind: "buzz", player: players(:lucia), delay_ms: 342, place: 1 } }
    )
    assert_includes html, "342 ms"
    assert_includes html, "1.º"
    assert_includes html, "data-sfx=\"buzzer_hit\""
  end

  test "lock pulse needs no player" do
    html = ApplicationController.render(partial: "shared/pulse", locals: { pulse: { kind: "lock" } })
    assert_includes html, "Cerrado"
    assert_includes html, "picto-hourglass"
    assert_includes html, "data-sfx=\"round_lock\""
  end

  test "open and reveal pulses cue players without a player name" do
    html = ApplicationController.render(partial: "shared/pulse", locals: { pulse: { kind: "open" } })
    assert_includes html, "Abierta"
    assert_includes html, "data-sfx=\"round_open\""
    html = ApplicationController.render(partial: "shared/pulse", locals: { pulse: { kind: "reveal" } })
    assert_includes html, "Respuesta"
    assert_includes html, "data-sfx=\"reveal\""
    html = ApplicationController.render(partial: "shared/pulse", locals: { pulse: { kind: "advance" } })
    assert_includes html, "Siguiente"
    assert_includes html, "data-sfx=\"question_change\""
  end

  test "round yaml chooses the opening and scoring cues" do
    html = ApplicationController.render(
      partial: "shared/pulse",
      locals: { pulse: { kind: "open" }, round: round_runs(:salomon) }
    )
    assert_includes html, "data-sfx=\"round_start\""
    html = ApplicationController.render(
      partial: "shared/pulse",
      locals: { pulse: { kind: "score", label: "Leones" }, round: round_runs(:david_goliath) }
    )
    assert_includes html, "data-sfx=\"fire_whoosh\""
    html = ApplicationController.render(
      partial: "shared/pulse",
      locals: { pulse: { kind: "lock" }, round: round_runs(:freeze_saul) }
    )
    assert_includes html, "data-sfx=\"dramatic_fire\""
    html = ApplicationController.render(
      partial: "shared/pulse",
      locals: { pulse: { kind: "miss", label: "Casa" } }
    )
    assert_includes html, "data-sfx=\"wrong_soft\""
  end
end
