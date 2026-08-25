require "test_helper"

class QuizAnswersControllerTest < ActionDispatch::IntegrationTest
  test "home draws a street quiz and a tap settles the board" do
    get root_path
    assert_response :success
    assert_select "#street_quiz.play-reel.is-quiz.is-street"
    assert_select "#street_quiz[data-controller~=quiz]"
    assert_select "#street_quiz[data-controller~=story]"
    assert_select "#street_quiz[data-story-street-value=true]"
    assert_select ".story-ticks", count: 0
    assert_select ".story-close", count: 0
    assert_select ".play-sheet-grip", count: 1
    assert_select ".street-map"
    assert_select ".play-sheet[data-sheet-snap=mid]"
    assert_select ".street-score span", text: "0"
    assert_select ".street-score.is-tick", count: 0
    assert_select ".choice-btn"
    assert_select "#street_quiz .btn.btn-gold", count: 0
    assert_select "details.home-menu a[href=?]", nights_path

    run = QuizRun.order(:id).last
    question = run.question
    post quiz_answers_path(run), params: { choice: question.correct_choice }, as: :turbo_stream
    assert_response :success
    assert_select ".quiz-board.is-settled"
    assert_select ".play-sheet[data-sheet-snap=open]"
    assert_select ".street-score.is-tick span", text: question.points.to_s
    assert_select ".street-points-burst", text: "+#{question.points}"
    assert_select "a.quiet-link .quiz-cite", text: /#{Regexp.escape(question.scripture.cite)}/
    assert_select "a.quiet-link", text: /#{Regexp.escape(I18n.t("quiz.read_more"))}/
    assert_select ".quiz-cite", count: 1
    assert_select ".btn.btn-gold.quiz-next", text: /#{Regexp.escape(I18n.t("quiz.next"))}/
    assert_select ".btn.btn-gold.quiz-next .picto-arrow"
    assert_select ".quiz-bars"
    assert_select ".quiz-bar.is-correct.is-right"
    assert_select ".quiz-flag"
    assert_match %r{churchofjesuschrist.org/study/scriptures/}, response.body
  end

  test "a miss marks the true choice and the wrong pick" do
    get root_path
    run = QuizRun.order(:id).last
    question = run.question
    miss = question.choices.map { |choice| choice["key"].to_s }.find { |key| key != question.correct_choice }
    post quiz_answers_path(run), params: { choice: miss }, as: :turbo_stream
    assert_response :success
    assert_select ".quiz-board.is-wrong"
    assert_select ".quiz-bar.is-correct.is-right"
    assert_select ".quiz-bar.is-wrong.is-miss"
    assert_select ".quiz-flag"
    assert_select ".play-sheet[data-sheet-snap=open]"
    assert_select ".street-score span", text: "0"
    assert_select ".street-score.is-tick", count: 0
    assert_select ".btn.btn-gold.quiz-next", text: /#{Regexp.escape(I18n.t("quiz.next"))}/
    assert_select ".btn.btn-gold.quiz-next .picto-arrow"
  end

  test "rewind shows the prior settled question and will not skip an ask" do
    get root_path
    run = QuizRun.order(:id).last
    post quiz_rewind_path(run), as: :turbo_stream
    assert_response :success
    assert_select ".choice-btn"
    assert_select ".quiz-progress", text: /1 \/ 10/

    post quiz_answers_path(run), params: { choice: run.question.correct_choice }, as: :turbo_stream
    post quiz_advance_path(run), as: :turbo_stream
    assert_select ".quiz-progress", text: /2 \/ 10/
    assert_select ".choice-btn"

    post quiz_rewind_path(run), as: :turbo_stream
    assert_select ".quiz-board.is-settled"
    assert_select ".play-sheet[data-sheet-snap=open]"
    assert_select ".quiz-progress", text: /1 \/ 10/
    assert_select ".street-score.is-tick span", text: run.reload.score.to_s
    assert_select ".btn.btn-gold.quiz-next", text: /#{Regexp.escape(I18n.t("quiz.next"))}/
    assert_select ".btn.btn-gold.quiz-next .picto-arrow"
  end

  test "advance walks to the next question" do
    get root_path
    run = QuizRun.order(:id).last
    post quiz_answers_path(run), params: { choice: run.question.correct_choice }, as: :turbo_stream
    post quiz_advance_path(run), as: :turbo_stream
    assert_response :success
    assert_select ".quiz-progress", text: /2 \/ 10/
    assert_select ".play-sheet[data-sheet-snap=mid]"
    assert_select ".street-score span", text: run.reload.score.to_s
    assert_select ".street-score.is-tick", count: 0
    assert_select "#street_quiz .btn.btn-gold", count: 0
  end

  test "expire freezes a miss" do
    get root_path
    run = QuizRun.order(:id).last
    post quiz_expire_path(run), as: :turbo_stream
    assert_response :success
    assert_select ".quiz-verdict.is-wrong"
  end
end
