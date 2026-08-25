require "test_helper"

class Quizzes::StandingsTest < ActiveSupport::TestCase
  setup do
    @ward = wards(:demo)
    @pili = people(:pili)
    @carmen = people(:carmen_garcia)
  end

  test "returns pack and total ranks with boards" do
    QuizRun.create!(
      device_digest: "stand-a",
      person: @pili,
      pack_id: "coronas",
      position: 10,
      score: 55,
      status: "finished",
      opened_at: Time.current
    )
    QuizRun.create!(
      device_digest: "stand-b",
      person: @carmen,
      pack_id: "coronas",
      position: 10,
      score: 90,
      status: "finished",
      opened_at: Time.current
    )

    standings = Quizzes::Standings.call(ward: @ward, person: @pili, pack_id: "coronas")

    assert_equal 2, standings.pack_rank
    assert_equal 55, standings.pack_score
    assert_equal 2, standings.total_rank
    assert standings.pack_board.rows.any?
    assert standings.total_board.rows.any?
    assert_equal "Explorador", standings.rank_title
  end

  test "returns nil without ward or person" do
    assert_nil Quizzes::Standings.call(ward: nil, person: @pili)
    assert_nil Quizzes::Standings.call(ward: @ward, person: nil)
  end
end
