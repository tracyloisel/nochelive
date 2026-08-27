require "test_helper"

class StreetPlaysControllerTest < ActionDispatch::IntegrationTest
  test "jugar requires an open run" do
    get jugar_path
    assert_redirected_to root_path
  end

  test "jugar shows overlay hud" do
    sign_in_congregation
    post street_profile_path, params: { guest: 1 }
    follow_redirect!
    post street_pack_start_path("coronas")
    follow_redirect!
    assert_select "#street_quiz.play-reel.is-street.is-overlay"
    assert_select ".quiz-hud"
    assert_select ".quiz-hud-streak"
    assert_select ".quiz-hud-score .picto-crown"
    assert_select ".quiz-hud-rail"
    assert_select ".street-quiz-head", count: 0
    assert_select "a.street-quiz-lockup", count: 0
    assert_select ".street-quiz-apex"
    assert_select ".quiz-sheet"
    assert_select ".street-score"
    assert_select ".street-shot-rival", count: 0
    assert_select ".street-level-rail", count: 0
    assert_select ".street-back-map", count: 0
    assert_select ".street-map", count: 0
    assert_select "a.home-menu-row[href=?]", street_map_path, text: I18n.t("street.ceremony_back_map")
    assert_select "a.home-menu-row[href=?]", jugar_path, text: I18n.t("street.menu_play")
    assert_select ".home-menu.is-split .chrome-face"
    assert_select ".chrome-drawer .mute"
    assert_select ".chrome-drawer .lang-switch.is-drawer"
    assert_select ".chrome-tools", count: 0
  end

  test "jugar ask leaves the timer band free of a chase chip" do
    freeze_time
    sign_in_congregation
    post street_profile_path, params: { guest: 1 }
    follow_redirect!
    post street_pack_start_path("coronas")
    follow_redirect!
    PersonDevice.where(person: people(:carmen_garcia)).update_all(last_seen_at: Time.current)
    QuizRun.order(:id).last.update!(position: 4, ends_at: 20.seconds.from_now)

    get jugar_path
    assert_select ".play-timer"
    assert_select ".street-shot-rival", count: 0
  end

  test "short timed ask does not start warn or hot" do
    freeze_time
    sign_in_congregation
    post street_profile_path, params: { guest: 1 }
    follow_redirect!
    start_street_play!("coronas")
    run = QuizRun.order(:id).last

    run.update!(position: 10, ends_at: 15.seconds.from_now)
    get jugar_path
    assert_select ".play-timer"
    assert_select ".play-timer.is-warn", count: 0
    assert_select ".play-timer.is-low", count: 0
    assert_select "#street_quiz[data-stage-timer-duration-value=?]", "15"

    travel 9.seconds
    get jugar_path
    assert_select ".play-timer.is-warn"
    assert_select ".play-timer.is-low", count: 0

    travel 3.seconds
    get jugar_path
    assert_select ".play-timer.is-low"
  end

  test "twenty-second street ask turns warn at eight seconds" do
    freeze_time
    sign_in_congregation
    post street_profile_path, params: { guest: 1 }
    follow_redirect!
    start_street_play!("coronas")
    run = QuizRun.order(:id).last
    run.update!(position: 4, ends_at: 20.seconds.from_now)
    get jugar_path
    assert_select ".play-timer.is-warn", count: 0
    assert_select ".play-timer.is-low", count: 0
    assert_select "#street_quiz[data-stage-timer-duration-value=?]", "20"

    travel 12.seconds
    get jugar_path
    assert_select ".play-timer.is-warn"
  end

  test "jugar opens the pack tapped on the map when two runs are open" do
    sign_in_congregation
    post street_profile_path, params: { guest: 1 }
    follow_redirect!
    start_street_play!("coronas")
    first = QuizRun.open_runs.order(:id).last
    first.update!(position: 10)
    Quizzes::Submit.call(run: first, choice_key: first.question.correct_choice)
    Quizzes::Complete.call(run: first.reload)

    post street_pack_start_path("placas")
    follow_redirect!
    placas = QuizRun.open_runs.find_by(pack_id: "placas")
    assert placas

    post street_pack_start_path("coronas")
    follow_redirect!
    replay = QuizRun.open_runs.find_by(pack_id: "coronas")
    assert replay
    assert_not_equal placas.id, replay.id

    post street_pack_start_path("placas")
    follow_redirect!
    assert_select "#street_quiz"
    assert_select "form[action=?]", quiz_answers_path(placas)
    assert_equal placas.id, session[:street_play_run_id]
  end
end
