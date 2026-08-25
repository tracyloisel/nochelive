require "test_helper"

class StreetHistoriesControllerTest < ActionDispatch::IntegrationTest
  test "history page lists the trail" do
    get root_path
    run = QuizRun.order(:id).last
    Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)

    get street_history_path
    assert_response :success
    assert_select "h1", text: I18n.t("street.history_title")
    assert_select ".street-history-step.correct"
  end

  test "jump from history returns to the quiz" do
    get root_path
    run = QuizRun.order(:id).last
    Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)
    Quizzes::Advance.call(run: run.reload)

    post quiz_jump_path(run), params: { position: 1 }
    assert_redirected_to root_path
  end
end
