require "test_helper"

class People::TransferTest < ActiveSupport::TestCase
  setup do
    @origin = wards(:demo)
    @person = people(:pili)
    @dest = extra_ward(41, listed: true)
    @run = quiz_runs(:pili_coronas)
  end

  test "moves the ficha and keeps quiz points on the new rama board" do
    before = Quizzes::Leaderboard.call(ward: @origin, person: @person, limit: 10)
    assert_equal 95, before.your_score
    refute_nil before.your_rank

    People::Transfer.call(person: @person, ward: @dest)
    @person.reload

    assert_equal @dest.id, @person.ward_id
    assert_nil @person.last_ward_team_id
    assert_equal 95, @run.reload.score
    assert_equal @person.id, @run.person_id

    origin_board = Quizzes::Leaderboard.call(ward: @origin, person: @person, limit: 10)
    dest_board = Quizzes::Leaderboard.call(ward: @dest, person: @person, limit: 10)

    assert_nil origin_board.your_rank
    assert_equal 0, origin_board.rows.count { |row| row.person.id == @person.id }
    assert origin_board.rows.any? { |row| row.person.given_name == "Carmen" }
    assert_equal 95, dest_board.your_score
    assert_equal 1, dest_board.your_rank
    assert dest_board.rows.first.you

    world = Quizzes::World.call(device_digest: @run.device_digest, person_id: @person.id)
    coronas = world.packs.find { |pack| pack.id == "coronas" }
    assert_equal :finished, coronas.state
    assert_equal 95, coronas.best_score
  end

  test "same rama is a no-op" do
    team_id = @person.last_ward_team_id
    People::Transfer.call(person: @person, ward: @origin)
    @person.reload
    assert_equal @origin.id, @person.ward_id
    assert_equal team_id, @person.last_ward_team_id
  end

end
