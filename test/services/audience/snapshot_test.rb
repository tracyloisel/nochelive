require "test_helper"

class Audience::SnapshotTest < ActiveSupport::TestCase
  test "delays open lock and reveal for the broadcast audience" do
    night = game_sessions(:david)
    round = round_runs(:salomon)
    start = Time.zone.parse("2026-08-28 20:00:00")
    night.update!(broadcast_delay_ms: 6_000)
    round.update!(phase: "open", opened_at: start, locked_at: nil, revealed_at: nil)

    assert Audience::Snapshot.new(night:, now: start + 5.seconds).intro?
    assert Audience::Snapshot.new(night:, now: start + 6.seconds).open?

    round.update!(phase: "locked", locked_at: start + 10.seconds)
    assert Audience::Snapshot.new(night:, now: start + 15.seconds).open?
    assert Audience::Snapshot.new(night:, now: start + 16.seconds).locked?

    round.update!(phase: "revealed", revealed_at: start + 20.seconds)
    assert Audience::Snapshot.new(night:, now: start + 25.seconds).locked?
    assert Audience::Snapshot.new(night:, now: start + 26.seconds).revealed?
  end

  test "never exposes the answer while delayed reveal is pending" do
    night = game_sessions(:david)
    round = round_runs(:salomon)
    revealed_at = Time.zone.parse("2026-08-28 20:00:20")
    night.update!(broadcast_delay_ms: 10_000)
    round.update!(phase: "revealed", revealed_at:)

    snapshot = Audience::Snapshot.new(night:, now: revealed_at + 9.seconds)
    assert snapshot.locked?
    assert_not snapshot.reveal_visible?
    assert snapshot.refresh_in_ms.positive?
  end
end
