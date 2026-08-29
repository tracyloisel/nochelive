require "test_helper"

class Quizzes::DuelCampusFriendsTest < ActiveSupport::TestCase
  test "an open invitation takes precedence over resolved pair history" do
    row = Quizzes::DuelCampusFriends.call(person: people(:pili), limit: 20)
      .find { |candidate| candidate.person == people(:carmen_garcia) }

    assert row
    assert_equal :invited, row.state
  end
end
