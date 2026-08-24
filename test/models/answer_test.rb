require "test_helper"

class AnswerTest < ActiveSupport::TestCase
  test "requires a short body" do
    answer = Answer.new(round_run: round_runs(:salomon), team: teams(:leones), player: players(:lucia))
    assert_not answer.valid?
    answer.body = "Sabiduría"
    assert answer.valid?
  end
end
