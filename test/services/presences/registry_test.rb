require "test_helper"

class Presences::RegistryTest < ActiveSupport::TestCase
  test "deduplicates one person across multiple street connections" do
    person = people(:pili)
    first = mark_person_online(person, connection_id: "street-pili")
    second = mark_person_online(person, connection_id: "second-pili")

    assert_equal 1, Presences::Registry.live_count
    assert Presences::Registry.person_online?(person.id)

    Presences::Registry.leave(first)
    assert Presences::Registry.person_online?(person.id)
    assert_equal 1, Presences::Registry.live_count

    Presences::Registry.leave(second)
    assert_not Presences::Registry.person_online?(person.id)
    assert_equal 0, Presences::Registry.live_count
  end

  test "expires a connection without touching PostgreSQL" do
    person = people(:pili)
    entry = mark_person_online(person, connection_id: "expiring-person")

    travel Presences::Registry::ACTIVE_WINDOW + 1.second do
      assert_not Presences::Registry.person_online?(person.id)
      assert_equal 0, Presences::Registry.live_count
    end

    assert Presences::Registry.touch(entry).platform_changed
  end

  test "filters online people by ward and candidate set" do
    pili = people(:pili)
    carmen = people(:carmen_garcia)
    mark_person_online(pili)
    mark_person_online(carmen)

    assert_equal Set[pili.id, carmen.id], Presences::Registry.online_person_ids(ward_id: wards(:demo).id)
    assert_equal Set[carmen.id], Presences::Registry.online_person_ids(among: [ carmen.id, people(:carmen_lopez).id ])
  end

  test "an active websocket heartbeat executes no SQL" do
    entry = mark_person_online(people(:pili))

    assert_queries_count(0) do
      change = Presences::Registry.touch(entry)
      assert_not change.platform_changed
    end
  end
end
