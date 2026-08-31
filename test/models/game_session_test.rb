require "test_helper"

class GameSessionTest < ActiveSupport::TestCase
  test "derives every phase from the configured schedule" do
    starts_at = Time.zone.parse("2026-08-29 20:00:00")
    night = GameSession.new(starts_at:, ends_at: starts_at + 3.hours, duration_hours: 3, status: "scheduled")

    assert_equal :scheduled, night.phase(at: starts_at - 31.minutes)
    assert_equal :lobby, night.phase(at: starts_at - 30.minutes)
    assert_equal :playing, night.phase(at: starts_at)
    assert_equal :playing, night.phase(at: starts_at + 2.hours)
    assert_equal :finished, night.phase(at: starts_at + 3.hours)
  end

  test "normalizes the end to the configured duration after the start" do
    night = game_sessions(:elias)
    night.starts_at = 3.days.from_now.change(usec: 0)
    night.duration_hours = 3
    night.valid?

    assert_equal night.starts_at + 3.hours, night.ends_at
  end

  test "requires an ordered non-empty quiz sequence" do
    night = game_sessions(:elias)
    night.quiz_pack_ids = []
    assert_not night.valid?
    night.quiz_pack_ids = %w[coronas coronas]
    assert_not night.valid?
  end
end
