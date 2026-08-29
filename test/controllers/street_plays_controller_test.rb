require "test_helper"

class StreetPlaysControllerTest < ActionDispatch::IntegrationTest
  test "jugar requires a player profile" do
    get jugar_path
    assert_redirected_to street_profile_path(quick: 1)
  end

  test "jugar shows overlay hud" do
    sign_in_congregation
    create_street_profile!
    post street_pack_start_path("coronas")
    follow_redirect!
    assert_select "#street_quiz.play-reel.is-street.is-overlay.is-art-preview"
    assert_select "#street_quiz[data-action*='pointerdown->quiz#revealArt']"
    assert_select "#street_quiz[data-controller~=story]", count: 0
    assert_select "#street_quiz[data-stage-bed-value=timer_tension][data-stage-bed-policy-value=continuous]"
    assert_includes response.body, "celestial_breath"
    assert_includes response.body, "street_wrong_soft"
    assert_includes response.body, "street_royal_fanfare"
    refute_includes response.body, "score_transfer"
    quiz_theme = css_select("#street_quiz").first["data-quiz-theme"]
    assert_includes %w[light dark], quiz_theme
    assert_select ".quiz-hud[data-hud-theme='celestial-#{quiz_theme}']"
    assert_select ".home-menu[data-hud-theme='celestial-#{quiz_theme}'] .chrome-drawer"
    assert_select ".quiz-hud-streak"
    assert_select ".quiz-hud-score .picto-crown"
    assert_select ".quiz-hud-rail"
    assert_select ".street-quiz-apex"
    assert_select ".quiz-sheet"
    assert_select ".street-score"
    assert_select ".street-shot-rival", count: 0
    assert_select ".street-back-map", count: 0
    assert_select ".street-map", count: 0
    assert_select "a.home-menu-invite[href=?]", street_challenges_path(anchor: "inviter"), text: /#{Regexp.escape(I18n.t("hub_menu.invite_friend"))}/
    assert_select "a.home-menu-row[href=?]", study_program_path, text: /#{Regexp.escape(I18n.t("study.title"))}/
    assert_select ".home-menu.is-split .chrome-face"
    assert_select ".chrome-drawer .mute"
    assert_select ".chrome-drawer .lang-switch.is-drawer"
    assert_select ".chrome-tools", count: 0
  end

  test "jugar ask leaves the timer band free of a chase chip" do
    freeze_time
    sign_in_congregation
    create_street_profile!
    post street_pack_start_path("coronas")
    follow_redirect!
    mark_person_online(people(:carmen_garcia))
    QuizRun.order(:id).last.update!(position: 4, ends_at: 20.seconds.from_now)

    get jugar_path
    assert_select ".quiz-dock > .quiz-timer-slot > .play-timer"
    assert_select ".street-shot-rival", count: 0
  end

  test "jugar loads the Campus rail while challenges are active" do
    sign_in_congregation
    person = people(:pili)
    post street_profile_path, params: { person_id: person.id, favorite_year: person.favorite_year }
    follow_redirect! while response.redirect?
    Quizzes::DuelInvitationClaim.call(
      invitation: duel_invitations(:named_pili_invitation),
      person: people(:carmen_garcia)
    )
    post street_pack_start_path("coronas")
    follow_redirect!
    run = QuizRun.open_runs.where(person:).order(:id).last

    assert_select "link[href*='duel_campus']"
    assert_select ".duel-quiz-rail.is-race-expanded.is-race-pending[aria-live=off][data-duel-race-run-value=?]", run.id.to_s
    assert_select ".duel-quiz-rail[data-duel-race-race-value][data-duel-race-signature-value]"
    assert_select ".duel-quiz-rail-count", text: /\d+/
  end

  test "short timed ask does not start warn or hot" do
    freeze_time
    sign_in_congregation
    create_street_profile!
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
    create_street_profile!
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
    create_street_profile!
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
