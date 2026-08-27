require "test_helper"

class Platform::StatsScreenTest < ActiveSupport::TestCase
  test "returns both stats and hud data" do
    screen = Platform::StatsScreen.call(
      person: people(:pili),
      ward: wards(:demo),
      device_digest: "test-digest"
    )

    assert_kind_of Platform::Stats::Result, screen.stats
    assert screen.hud

    assert screen.stats.people > 0
    assert screen.stats.wards > 0
    assert screen.stats.countries > 0
    assert screen.stats.answers > 0
  end

  test "hud kind is street for authenticated person" do
    screen = Platform::StatsScreen.call(
      person: people(:pili),
      ward: wards(:demo),
      device_digest: "test-digest"
    )

    assert_equal :street, screen.hud.kind
    assert_not screen.hud.guest?
    assert screen.hud.name
  end

  test "hud returns street result for guests (not nil)" do
    screen = Platform::StatsScreen.call(
      person: nil,
      ward: nil,
      device_digest: "guest-digest"
    )

    assert screen.hud
    assert screen.hud.guest?
    assert_equal :street, screen.hud.kind
    assert_nil screen.hud.name
    assert_nil screen.hud.rank_key
  end

  test "stats include path_share as float" do
    screen = Platform::StatsScreen.call(
      person: nil,
      ward: nil,
      device_digest: "test-digest"
    )

    assert_kind_of Float, screen.stats.path_share
  end
end