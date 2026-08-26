require "test_helper"

class QuizJumpsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_congregation
    post street_profile_path, params: { guest: 1 }
    follow_redirect!
    start_street_jugar!
  end

  test "jump returns to an answered question" do
    run = QuizRun.order(:id).last
    Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)
    Quizzes::Advance.call(run: run.reload)

    post quiz_jump_path(run), params: { position: 1 }, as: :turbo_stream
    assert_response :success
    assert_match(/street-shot-actions/, response.body)
    assert_match(/quiz-board is-settled/, response.body)
    refute_match(/street-quiz-dock/, response.body)
  end
end
