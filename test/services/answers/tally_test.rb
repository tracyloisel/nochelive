require "test_helper"

class Answers::TallyTest < ActiveSupport::TestCase
  test "counts percent per choice" do
    round = round_runs(:elias_carmel)
    round.update!(phase: "open", opened_at: Time.current)
    Answers::Submit.call(round:, team: teams(:casa), player: players(:daniel), body: "fire")
    Answers::Submit.call(round:, team: teams(:leones), player: players(:lucia), body: "rain")

    rows = Answers::Tally.call(round:)
    by_key = rows.index_by(&:key)

    assert_equal 4, rows.size
    assert_equal 50, by_key["fire"].percent
    assert_equal 50, by_key["rain"].percent
    assert_equal 0, by_key["wind"].percent
    assert_equal 0, by_key["oil"].percent
    assert by_key["fire"].correct
    assert_not by_key["rain"].correct
  end

  test "zero answers stay at zero" do
    round = round_runs(:rey_o_profeta)
    rows = Answers::Tally.call(round:)
    assert rows.all? { |row| row.percent.zero? }
  end
end
