require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "home and health" do
    get root_path
    assert_response :success
    get "/up"
    assert_response :success
  end

  test "home opens a street quiz reel" do
    get root_path
    assert_response :success
    assert_select "#profile_gate .profile-gate"
    assert_select "#street_quiz.play-reel.is-quiz.is-street"
    assert_select "#street_quiz[data-controller~=quiz]"
    assert_select "#street_quiz[data-controller~=story]"
    assert_select "#street_quiz[data-story-street-value=true]"
    assert_select "#street_quiz[data-stage-sfx-value=question_change]"
    assert_select ".home-paper", count: 0
    assert_select ".story-ticks", count: 0
    assert_select ".story-close", count: 0
    assert_select ".play-sheet-grip", count: 1
    assert_select ".street-map"
    assert_select ".play-sheet[data-sheet-snap=mid]"
    assert_select ".street-score span", text: "0"
    assert_select ".street-score.is-tick", count: 0
    assert_select ".choice-btn"
    assert_select "#street_quiz .btn.btn-gold", count: 0
    assert_select "details.home-menu:not([open])"
    assert_select "details.home-menu a[href=?]", nights_path, text: I18n.t("home.nights")
    assert_select "details.home-menu a[href=?]", search_path
    assert_select "details.home-menu a[href=?]", about_path
    assert_select "details.home-menu a[href=?]", street_profile_path, text: I18n.t("street.profile_menu")
    assert_select "details.home-menu a[href=?]", street_history_path, text: I18n.t("street.history_menu")
    assert_select ".street-person"
    assert_select "details.home-menu .place-input", count: 0
    assert_select ".ward-grid", count: 0
    assert_select ".chrome-tools .mute + .lang-switch"
    assert_select ".lang-switch > summary .picto-flag-es"
    assert_select "details.home-menu .lang-switch", count: 0
  end

  test "a timed street question exposes stage timer data on the reel" do
    get root_path
    run = QuizRun.order(:id).last
    run.update!(position: 4, ends_at: 20.seconds.from_now)
    get root_path
    assert_select "#street_quiz[data-stage-timer-end-value]"
    assert_select "#street_quiz[data-stage-timer-duration-value=20]"
    assert_select "#street_quiz[data-stage-bed-value=timer_tension]"
    assert_select ".play-timer"
  end

  test "guest mode hides the profile gate" do
    sign_in_congregation
    post street_profile_path, params: { guest: 1 }
    follow_redirect!
    assert_select "#profile_gate", count: 0
    assert_select "#street_quiz"
    assert_select ".street-person.is-guest"
  end

  test "remembered rama does not steal the street quiz" do
    sign_in_congregation
    get root_path
    assert_response :success
    assert_select "#street_quiz"
    assert_select ".home-paper", count: 0
  end
end
