require "test_helper"

class Quizzes::DuelCampusSummaryTest < ActiveSupport::TestCase
  Counts = Data.define(:active, :incoming)
  Campus = Data.define(:counts)

  test "uses the same live crowns and Campus counters for every surface" do
    person = people(:pili)
    campus = Campus.new(counts: Counts.new(active: 3, incoming: 2))

    summary = Quizzes::DuelCampusSummary.call(person:, campus:)

    assert_equal Quizzes::Complete.total_best(person), summary.crowns
    assert_equal 3, summary.active
    assert_equal 2, summary.incoming
  end

  test "keeps the public Hub honest without a selected player" do
    summary = Quizzes::DuelCampusSummary.call(person: nil, campus: nil)

    assert_equal 0, summary.crowns
    assert_equal 0, summary.active
    assert_equal 0, summary.incoming
  end
end
