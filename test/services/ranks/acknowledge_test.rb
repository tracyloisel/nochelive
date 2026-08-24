require "test_helper"

class Ranks::AcknowledgeTest < ActiveSupport::TestCase
  test "clears the ceremony and keeps Rey" do
    team = teams(:casa)
    team.update!(pending_rank_up: "Explorador", next_correct_doubled: true, rank_key: "explorador")

    Ranks::Acknowledge.call(team:)

    team.reload
    assert_nil team.pending_rank_up
    assert team.next_correct_doubled?
    assert_equal "Explorador", team.rank_label
  end
end
