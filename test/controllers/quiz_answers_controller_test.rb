require "test_helper"

class QuizAnswersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_congregation
    create_street_profile!
    start_street_play!
  end

  test "jugar draws a street quiz and a tap settles the board" do
    get jugar_path
    assert_response :success
    assert_select "#street_quiz.play-reel.is-quiz.is-street.is-overlay.is-art-preview"
    assert_select ".quiz-hud-rail"
    assert_select ".choice-btn"
    assert_select ".choice-btn .quiz-letter"
    assert_select "turbo-frame#scripture_reader"

    run = QuizRun.order(:id).last
    question = run.question
    post quiz_answers_path(run), params: { choice: question.correct_choice }, as: :turbo_stream
    assert_response :success
    assert_select "#street_quiz.is-art-preview", count: 0
    assert_select ".quiz-board.is-settled"
    assert_select ".quiz-bar .word"
    assert_select ".quiz-bar .quiz-meta .quiz-pct"
    assert_select ".quiz-bar .choice-mark", count: 0
    assert_select ".quiz-bar.is-correct .quiz-flag.is-yes .picto-tick", count: 1
    assert_select ".quiz-bar:not(.is-correct) .quiz-flag.is-no .picto-cross"
    assert_select ".quiz-meta .quiz-flag", count: 0
    assert_select ".quiz-hud-score [data-quiz-target=score]"
    assert_select ".quiz-hud-score .picto-crown"
    assert_select ".quiz-hud .street-points-pop", count: 0
    assert_select ".quiz-hud-streak[data-tier=spark] .quiz-hud-streak-num", text: "1"
    assert_select "#street_quiz[data-quiz-to-score-value=?]", question.points.to_s
    shout = ApplicationController.helpers.street_praise_line(run, question)
    assert_select ".street-praise"
    assert_select ".street-praise.is-streak", count: 0
    assert_select ".street-praise-line", text: shout
    assert_select ".street-praise-pts", text: "+#{question.points}"
    assert_select ".quiz-streak-shout", count: 0
    assert_select ".quiz-hud-streak.is-shout", count: 0
    assert_select ".quiz-board.is-settled .quiz-shout", count: 0
    assert_select ".play-shot .street-shot-actions .quiz-next"
    assert_select ".play-shot a.quiz-scripture[data-turbo-frame=scripture_reader][href*='/escrituras/']"
    assert_select ".play-shot a.quiz-scripture .quiz-read", text: I18n.t("quiz.read")
    assert_select ".play-shot a.quiz-scripture .quiz-cite", text: question.scripture.cite
    assert_select ".play-shot a.quiz-scripture[href*='cite=']"
    assert_select ".play-shot a.quiz-scripture[href*='churchofjesuschrist.org']", count: 0
    assert_select ".play-shot a.quiz-scripture[target=_blank]", count: 0
    assert_select ".quiz-board.is-settled .quiz-next", count: 0
    assert_select ".quiz-board.is-settled .quiz-scripture", count: 0
    assert_select ".street-quiz-dock", count: 0
  end

  test "a miss marks the true choice and the wrong pick" do
    run = QuizRun.order(:id).last
    question = run.question
    miss = question.choices.map { |choice| choice["key"].to_s }.find { |key| key != question.correct_choice }
    post quiz_answers_path(run), params: { choice: miss }, as: :turbo_stream
    assert_response :success
    assert_select ".quiz-board.is-wrong"
    assert_select ".street-score span", text: "0"
    assert_select ".quiz-hud-streak[data-tier=idle] .quiz-hud-streak-num", text: "0"
    assert_select ".street-praise.is-miss"
    assert_select ".street-praise-line", text: I18n.t("quiz.almost")
    assert_select ".quiz-shout", count: 0
    assert_select ".quiz-bar.is-correct .quiz-flag.is-yes .picto-tick", count: 1
    assert_select ".quiz-bar.is-wrong.is-miss .quiz-flag.is-no .picto-cross", count: 1
    assert_select ".quiz-bar:not(.is-correct) .quiz-flag.is-no .picto-cross"
  end

  test "the combo stays in the HUD after next and a miss snuffs it" do
    run = QuizRun.order(:id).last
    question = run.question
    post quiz_answers_path(run), params: { choice: question.correct_choice }, as: :turbo_stream
    post quiz_advance_path(run), as: :turbo_stream
    get jugar_path
    assert_select ".quiz-hud-streak[data-tier=spark] .quiz-hud-streak-num", text: "1"
    assert_select ".quiz-streak-shout", count: 0
    assert_select ".street-praise.is-streak", count: 0

    run.reload
    miss = (run.question.choices.map { |choice| choice["key"].to_s }.find { |key| key != run.question.correct_choice })
    post quiz_answers_path(run), params: { choice: miss }, as: :turbo_stream
    assert_select ".quiz-hud-streak.is-break[data-tier=idle] .quiz-hud-streak-num", text: "0"
  end

  test "two hits shout on the still and ten hits flash the gold veil" do
    run = QuizRun.order(:id).last
    post quiz_answers_path(run), params: { choice: run.question.correct_choice }, as: :turbo_stream
    post quiz_advance_path(run), as: :turbo_stream
    run.reload
    post quiz_answers_path(run), params: { choice: run.question.correct_choice }, as: :turbo_stream
    assert_select ".street-praise.is-streak.is-glow .street-praise-line", text: I18n.t("quiz.streak_two")
    assert_select ".quiz-hud-streak.is-shout[data-tier=glow] .quiz-hud-streak-num", text: "2"
    assert_select ".quiz-streak-shout", count: 0
    assert_select "#street_quiz[data-quiz-combo-shout-value=two]"

    8.times do
      post quiz_advance_path(run), as: :turbo_stream
      run.reload
      post quiz_answers_path(run), params: { choice: run.question.correct_choice }, as: :turbo_stream
    end
    assert_select ".street-praise.is-streak.is-legend .street-praise-line", text: I18n.t("quiz.streak_ten")
    assert_select ".quiz-hud-streak.is-shout[data-tier=legend] .quiz-hud-streak-num", text: "10"
    assert_select "#street_quiz[data-quiz-combo-shout-value=ten]"
    assert_select "#street_quiz[data-stage-fx-value=level]"
  end

  test "rewind shows the prior settled question and will not skip an ask" do
    run = QuizRun.order(:id).last
    post quiz_answers_path(run), params: { choice: run.question.correct_choice }, as: :turbo_stream
    post quiz_rewind_path(run), as: :turbo_stream
    assert_response :success
    assert_select ".quiz-board.is-settled"
  end

  test "advance on the last question opens the pack ceremony" do
    run = QuizRun.order(:id).last
    pack = QuizDefinition.catalog.find_pack(run.pack_id)
    question = pack.question_at(10)
    run.update!(position: 10, score: 80, ends_at: nil)
    post quiz_answers_path(run), params: { choice: question.correct_choice }, as: :turbo_stream
    run.quiz_answers.update_all(duration_ms: 77_000)
    post quiz_advance_path(run), as: :turbo_stream
    assert_response :success
    assert_select "#street_quiz.is-overlay.is-ceremony"
    assert_select ".quiz-hud"
    assert_select ".street-ceremony-hero"
    assert_select ".street-ceremony-shout"
    assert_select ".street-ceremony-kicker"
    assert_select ".street-ceremony-medallion"
    assert_select ".street-ceremony-stats .street-ceremony-stat", count: 4
    assert_select ".street-ceremony-stat", text: /01:17/
    assert_select ".street-ceremony-boards .street-ceremony-board", count: 2
    assert_select ".street-ceremony-chest-img"
    assert_select ".street-ceremony-laurel"
    assert_select ".street-ceremony-map", text: I18n.t("street.ceremony_back_map")
    assert_select ".street-ceremony-map .street-ceremony-map-icon"
    assert_select ".street-ceremony-map .street-ceremony-button-label"
    assert_select ".street-ceremony-afterplay"
    assert_select ".street-ceremony-secondary-actions"
    assert_select ".street-challenge-btn .street-ceremony-button-tail"
    assert_select ".street-ceremony-actions > .street-ceremony-viral-cta[data-action='street-share#challenge'][data-street-share-run-id-value='#{run.id}']"
    assert_select ".street-ceremony-share .street-ceremony-button-label", text: I18n.t("street.share_my_score")
    assert_select ".quiz-hud-gain"
    assert_select ".quiz-hud-streak-tag"
    assert_select ".quiz-hud-dot.is-done", count: 10
    assert_select "#street_quiz[data-stage-fx-value=none]"
    assert_select ".street-ceremony-lockup", count: 0
    assert_select ".street-ceremony-plinth", count: 0
    assert_select ".street-card.is-share", count: 0
    assert_select ".street-win-score.score-fly" do |nodes|
      score = nodes.first
      refute_equal "0", score["data-final"]
      assert score["data-from"].present?
    end
  end

  test "expire freezes a miss" do
    run = QuizRun.order(:id).last
    run.update!(position: 4, ends_at: 1.second.ago)
    post quiz_expire_path(run), as: :turbo_stream
    assert_response :success
    assert_select ".quiz-board.is-wrong"
    assert_select ".street-praise.is-miss"
  end
end
