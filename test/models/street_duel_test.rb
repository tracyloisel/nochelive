require "test_helper"

class StreetDuelTest < ActiveSupport::TestCase
  test "member projections do not expose either side to a stranger" do
    duel = street_duels(:pili_vs_carmen)
    stranger = people(:carmen_lopez)

    assert_nil duel.other_person_for(stranger)
    assert_nil duel.score_for(stranger)
    assert_nil duel.other_score_for(stranger)
    assert_nil duel.run_for(stranger)
    assert_nil duel.result_seen_at_for(stranger)
  end
end
