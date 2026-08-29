require "test_helper"

class Quizzes::StreakRewardTest < ActiveSupport::TestCase
  setup do
    @run = Quizzes::Draw.call(device_digest: GameSession.digest_token("streak-reward-device")).run
  end

  test "a perfect ten awards 89 points with a capped five-point bonus" do
    10.times do |index|
      run = @run.reload
      Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)
      Quizzes::Advance.call(run: @run.reload) unless index == 9
    end

    answers = @run.reload.quiz_answers.order(:id)
    assert_equal [ 5, 7, 8, 9, 10, 10, 10, 10, 10, 10 ], answers.pluck(:points_awarded)
    assert_equal [ 0, 2, 3, 4, 5, 5, 5, 5, 5, 5 ], answers.pluck(:streak_bonus)
    assert_equal 89, @run.score
  end

  test "a miss banks the score, loses the active bonus, and the next hit restarts at five" do
    5.times do
      run = @run.reload
      Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)
      Quizzes::Advance.call(run: @run.reload)
    end
    assert_equal 39, @run.reload.score

    run = @run.reload
    wrong = (run.question.choices.map { |choice| choice["key"] } - [ run.question.correct_choice ]).first
    miss = Quizzes::Submit.call(run:, choice_key: wrong)
    assert_equal 39, @run.reload.score
    assert_equal 5, miss.streak_before
    assert_equal 0, miss.streak_after
    assert_equal 5, miss.bonus_lost
    assert_equal 0, miss.points_awarded

    Quizzes::Advance.call(run: @run.reload)
    run = @run.reload
    restart = Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)
    assert_equal 5, restart.points_awarded
    assert_equal 44, @run.reload.score
  end

  test "remaining potential follows the current streak" do
    assert_equal 89, Quizzes::StreakReward.remaining_potential(run: @run)
    Quizzes::Submit.call(run: @run, choice_key: @run.question.correct_choice)
    assert_equal 84, Quizzes::StreakReward.remaining_potential(run: @run.reload)
  end

  test "an open legacy run is normalized before its next answer" do
    question = @run.question
    legacy = @run.quiz_answers.create!(
      device_digest: @run.device_digest,
      pack_id: @run.pack_id,
      question_id: question.id,
      choice_key: question.correct_choice,
      correct: true
    )
    @run.update!(score: question.points)
    Quizzes::Advance.call(run: @run.reload)

    run = @run.reload
    second = Quizzes::Submit.call(run:, choice_key: run.question.correct_choice)

    assert_equal 5, legacy.reload.points_awarded
    assert_equal 7, second.points_awarded
    assert_equal 12, @run.reload.score
  end
end
