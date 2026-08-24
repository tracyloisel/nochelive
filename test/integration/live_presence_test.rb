require "test_helper"

class LivePresenceTest < ActionDispatch::IntegrationTest
  setup { @night = game_sessions(:david) }

  test "watch shows who is live in the room and at home" do
    players(:lucia).update_column(:last_seen_at, Time.current)
    players(:daniel).update_column(:last_seen_at, Time.current)
    get night_watch_path(@night.code)
    assert_response :success
    assert_select ".presence"
    assert_select ".presence-stat .word", text: "en vivo"
    assert_select ".presence-stat .word", text: "sala"
    assert_select ".presence-stat .word", text: "casa"
    assert_select ".presence-face.is-live"
    assert_select "#live_pulses"
  end

  test "empty watch HUD waits for people" do
    night = create_night
    get night_watch_path(night.code)
    assert_response :success
    assert_select ".presence-wait"
    assert_select ".word", text: "Nadie aún"
    assert_select ".quiet", text: "Aún no hay equipos"
  end

  test "play shows team faces on the presence bar" do
    sign_in_as_participant(@night, name: "Sofía", team: teams(:leones))
    get night_play_path(@night.code)
    assert_response :success
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
  end
end
