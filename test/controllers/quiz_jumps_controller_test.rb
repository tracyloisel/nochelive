require "test_helper"

class QuizJumpsControllerTest < ActionDispatch::IntegrationTest
  test "jump returns to an answered question" do
    get root_path
    run = QuizRun.order(:id).last
    Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)
    Quizzes::Advance.call(run: run.reload)

    post quiz_jump_path(run), params: { position: 1 }, as: :turbo_stream
    assert_response :success
    assert_match(/street-quiz-dock/, response.body)
    assert_match(/quiz-board is-settled/, response.body)
  end
end
