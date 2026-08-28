require "test_helper"

class Presences::RegistryTest < ActiveSupport::TestCase
  test "deduplicates one person across street and night connections" do
    person = people(:pili)
    player = players(:lucia)
    player.update!(person:)

    street = mark_person_online(person, connection_id: "street-pili")
    night = mark_player_online(player.reload, connection_id: "night-pili")

    assert_equal 1, Presences::Registry.live_count
    assert Presences::Registry.person_online?(person.id)
    assert Presences::Registry.player_online?(player.id, night_id: player.game_session_id)

    Presences::Registry.leave(street)
    assert Presences::Registry.person_online?(person.id)
    assert_equal 1, Presences::Registry.live_count

    Presences::Registry.leave(night)
    assert_not Presences::Registry.person_online?(person.id)
    assert_equal 0, Presences::Registry.live_count
  end

  test "expires a connection without touching PostgreSQL" do
    player = players(:lucia)
    original_seen_at = 2.days.ago.change(usec: 0)
    player.update_column(:last_seen_at, original_seen_at)
    entry = mark_player_online(player, connection_id: "expiring-player")

    travel Presences::Registry::ACTIVE_WINDOW + 1.second do
      assert_not Presences::Registry.player_online?(player.id, night_id: player.game_session_id)
      assert_equal 0, Presences::Registry.live_count
    end

    assert_equal original_seen_at, player.reload.last_seen_at
    assert Presences::Registry.touch(entry).night_changed
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
    entry = mark_player_online(players(:lucia))

    assert_queries_count(0) do
      change = Presences::Registry.touch(entry)
      assert_not change.platform_changed
      assert_not change.night_changed
    end
  end
end
