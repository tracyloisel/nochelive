require "test_helper"

class Quizzes::StarsTest < ActiveSupport::TestCase
  test "star thresholds follow curve" do
    max = QuizDefinition::CURVE_POINTS.sum
    assert_equal 1, Quizzes::Stars.call(score: 10)
    assert_equal 2, Quizzes::Stars.call(score: (max * 0.6).ceil)
    assert_equal 3, Quizzes::Stars.call(score: (max * 0.85).ceil)
  end
end
