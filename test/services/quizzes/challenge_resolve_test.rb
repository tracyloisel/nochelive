require "test_helper"

class Quizzes::ChallengeResolveTest < ActiveSupport::TestCase
  test "resolves when both scores present" do
    duel = street_duels(:pili_vs_carmen)
    result = Quizzes::ChallengeResolve.call(duel:)
    assert result.duel.resolved?
    assert_equal people(:carmen_garcia), result.winner
  end
end
