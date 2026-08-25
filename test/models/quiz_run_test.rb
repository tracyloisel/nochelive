require "test_helper"

class QuizRunTest < ActiveSupport::TestCase
  test "open run is not timed on the first questions" do
    run = quiz_runs(:open_coronas)
    refute run.timed?
    assert_equal "ungio_david", run.question.id
    refute run.settled?
  end

  test "finished fixture is done" do
    run = quiz_runs(:crowd_milagros)
    assert run.finished?
    assert_equal 10, run.position
  end
end
