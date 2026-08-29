require "test_helper"

class Quizzes::StarsTest < ActiveSupport::TestCase
  test "star thresholds follow the streak economy" do
    max = Quizzes::StreakReward.max_pack_score
    assert_equal 89, max
    assert_equal 1, Quizzes::Stars.call(score: 10)
    assert_equal 2, Quizzes::Stars.call(score: (max * 0.6).ceil)
    assert_equal 3, Quizzes::Stars.call(score: (max * 0.85).ceil)
  end
end
