require "test_helper"

class Quizzes::LeaderboardTest < ActiveSupport::TestCase
  setup do
    @ward = wards(:demo)
    @pili = people(:pili)
    @carmen = people(:carmen_garcia)
  end

  test "ranks the best pack score per person in the ward" do
    QuizRun.create!(
      device_digest: "leader-a",
      person: @pili,
      pack_id: "coronas",
      position: 10,
      score: 50,
      status: "finished",
      opened_at: Time.current
    )
    QuizRun.create!(
      device_digest: "leader-b",
      person: @carmen,
      pack_id: "coronas",
      position: 10,
      score: 80,
      status: "finished",
      opened_at: Time.current
    )
    QuizRun.create!(
      device_digest: "leader-c",
      person: @pili,
      pack_id: "coronas",
      position: 10,
      score: 60,
      status: "finished",
      opened_at: Time.current
    )

    board = Quizzes::Leaderboard.call(ward: @ward, pack_id: "coronas", person: @pili, limit: 5)

    assert_equal 2, board.rows.size
    assert_equal @carmen, board.rows.first.person
    assert_equal 80, board.rows.first.score
    assert_equal 2, board.your_rank
    assert_equal 60, board.your_score
    assert board.rows.second.you
  end

  test "totals best pack scores across the ward" do
    QuizRun.create!(
      device_digest: "total-a",
      person: @pili,
      pack_id: "coronas",
      position: 10,
      score: 40,
      status: "finished",
      opened_at: Time.current
    )
    QuizRun.create!(
      device_digest: "total-b",
      person: @pili,
      pack_id: "milagros",
      position: 10,
      score: 30,
      status: "finished",
      opened_at: Time.current
    )
    QuizRun.create!(
      device_digest: "total-c",
      person: @carmen,
      pack_id: "coronas",
      position: 10,
      score: 90,
      status: "finished",
      opened_at: Time.current
    )

    board = Quizzes::Leaderboard.call(ward: @ward, person: @pili, limit: 5)

    assert_equal 90, board.rows.first.score
    assert_equal @carmen, board.rows.first.person
    assert_equal 70, board.your_score
    assert_equal 2, board.your_rank
  end
end
