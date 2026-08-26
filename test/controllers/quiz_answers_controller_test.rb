require "test_helper"

class QuizAnswersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_congregation
    post street_profile_path, params: { guest: 1 }
    follow_redirect!
    start_street_play!
  end

  test "jugar draws a street quiz and a tap settles the board" do
    get jugar_path
    assert_response :success
    assert_select "#street_quiz.play-reel.is-quiz.is-street"
    assert_select ".street-level-rail"
    assert_select ".choice-btn"
    assert_select "turbo-frame#scripture_reader"

    run = QuizRun.order(:id).last
    question = run.question
    post quiz_answers_path(run), params: { choice: question.correct_choice }, as: :turbo_stream
    assert_response :success
    assert_select ".quiz-board.is-settled"
    assert_select ".quiz-bar .word"
    assert_select ".quiz-bar .quiz-meta .quiz-pct"
    assert_select ".quiz-bar .choice-mark", count: 0
    assert_select ".quiz-bar.is-correct .quiz-flag.is-yes .picto-tick", count: 1
    assert_select ".quiz-bar:not(.is-correct) .quiz-flag.is-no .picto-cross"
    assert_select ".quiz-meta .quiz-flag", count: 0
    assert_select ".street-score.is-tick span", text: question.points.to_s
    assert_select ".street-points-pop", text: "+#{question.points}"
    shout = ApplicationController.helpers.street_praise_line(run, question)
    assert_select ".street-praise"
    assert_select ".street-praise-line", text: shout
    assert_select ".street-praise-pts", text: "+#{question.points}"
    assert_select ".quiz-board.is-settled .quiz-shout", count: 0
    assert_select ".play-shot .street-shot-actions .quiz-next"
    assert_select ".play-shot a.quiz-scripture.btn.btn-navy[data-turbo-frame=scripture_reader][href*='/escrituras/']"
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
    assert_select ".street-praise", count: 0
    assert_select ".quiz-shout", text: I18n.t("quiz.incorrect")
    assert_select ".quiz-bar.is-correct .quiz-flag.is-yes .picto-tick", count: 1
    assert_select ".quiz-bar.is-wrong.is-miss .quiz-flag.is-no .picto-cross", count: 1
    assert_select ".quiz-bar:not(.is-correct) .quiz-flag.is-no .picto-cross"
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
    post quiz_advance_path(run), as: :turbo_stream
    assert_response :success
    assert_select ".street-ceremony-lockup"
    assert_select ".street-ceremony-lockup-live"
    assert_select ".street-ceremony-filigree"
    assert_select ".street-ceremony-lockup-mark-img"
    assert_select ".street-ceremony-laurel"
    assert_select ".street-ceremony-monument"
    assert_select ".street-ceremony-trophy"
    assert_select ".street-ceremony-slab"
    assert_select ".street-ceremony-plinth"
    assert_select ".street-ceremony-chest-img"
    assert_select ".street-ceremony-ward-card"
    assert_select ".street-ceremony-plinth-grid"
    assert_select ".street-ceremony-monument .street-ceremony-trophy .street-ceremony-slab"
    assert_select ".street-ceremony-monument .street-ceremony-plinth .street-ceremony-actions"
    assert_select ".street-ceremony-map", text: I18n.t("street.ceremony_back_map")
    assert_select ".street-challenge-btn"
    assert_select ".street-card.is-share", count: 0
    assert_select ".street-win-score.score-fly" do |nodes|
      score = nodes.first
      assert_equal score["data-final"], score.text.strip
      refute_equal "0", score.text.strip
    end
  end

  test "expire freezes a miss" do
    run = QuizRun.order(:id).last
    run.update!(position: 4, ends_at: 1.second.ago)
    post quiz_expire_path(run), as: :turbo_stream
    assert_response :success
    assert_select ".quiz-verdict.is-wrong"
  end
end
