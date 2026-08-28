require "test_helper"

class Quizzes::ChallengeRivalsTest < ActiveSupport::TestCase
  test "live people sit above the rest" do
    mark_person_online(people(:carmen_lopez))
    rows = Quizzes::ChallengeRivals.call(
      ward: wards(:demo),
      person: people(:pili),
      pack_id: "coronas"
    )
    assert_equal people(:carmen_lopez).id, rows.first.person.id
    assert rows.first.live
  end

  test "resolved pair on the pack is marked lost or won" do
    rows = Quizzes::ChallengeRivals.call(
      ward: wards(:demo),
      person: people(:pili),
      pack_id: "coronas"
    )
    carmen = rows.find { |row| row.person.id == people(:carmen_garcia).id }
    assert_equal :lost, carmen.state
  end
end
