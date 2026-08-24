require "test_helper"

class RoundRunTest < ActiveSupport::TestCase
  setup do
    @round = round_runs(:salomon)
  end

  test "predicates follow phase" do
    assert @round.open?
    assert @round.live?
    assert @round.accepting_buzzes?
    assert_not @round.accepting_answers?
  end

  test "choice rounds accept answers while open" do
    round = round_runs(:rey_o_profeta)
    round.update!(phase: "open")
    assert round.accepting_answers?
  end

  test "lock then reveal then complete" do
    @round.lock!
    assert @round.locked?
    assert @round.accepting_answers?
    @round.reveal!
    assert @round.revealed?
    @round.complete!
    assert @round.completed?
    assert_not @round.may_complete?
  end

  test "begin answering and medals" do
    @round.lock!
    @round.begin_answering!
    assert @round.answering?
    assert_equal "2.º", Buzz.new(position: 2).medal
    assert_equal "3.º", Buzz.new(position: 3).medal
    assert_equal "7.º", Buzz.new(position: 7).medal
  end

  test "rejects an illegal transition" do
    assert_raises(RuntimeError) { @round.intro! }
  end

  test "intro is a no-op when already intro" do
    round = round_runs(:rey_o_profeta)
    round.intro!
    assert_nothing_raised { round.intro! }
    assert round.intro?
  end

  test "answering team is the first unscored buzz" do
    round = round_runs(:salomon)
    Buzz.accept!(round_run: round, team: teams(:leones), player: players(:lucia))
    assert_equal teams(:leones), round.answering_team
  end

  test "first buzz is position one" do
    assert_equal buzzes(:lucia_first), round_runs(:daniel_lions).first_buzz
    assert buzzes(:lucia_first).first?
    assert_equal "1.º", buzzes(:lucia_first).medal
  end

  test "timed window follows duration after open" do
    freeze_time do
      @round.update!(opened_at: Time.current, phase: "open")
      assert @round.timed?
      assert_equal 30, @round.seconds_left
      assert_equal Time.current + 30.seconds, @round.ends_at
    end
    @round.update!(phase: "revealed")
    assert_not @round.timed?
  end
end
