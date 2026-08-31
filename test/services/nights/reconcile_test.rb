require "test_helper"

class Nights::ReconcileTest < ActiveSupport::TestCase
  test "opens lobby, starts play, and closes idempotently" do
    night = game_sessions(:elias)
    starts_at = 1.hour.from_now.change(usec: 0)
    night.update_columns(starts_at:, ends_at: starts_at + 1.hour, status: "scheduled", closed_at: nil)

    assert_equal "lobby", Nights::Reconcile.call(night:, at: starts_at - 10.minutes).status
    assert_equal "playing", Nights::Reconcile.call(night:, at: starts_at + 1.second).status
    closed = Nights::Reconcile.call(night:, at: starts_at + 1.hour)
    assert_equal "finished", closed.status
    assert_equal closed.closed_at, Nights::Reconcile.call(night: closed, at: starts_at + 2.hours).closed_at
  end
end
