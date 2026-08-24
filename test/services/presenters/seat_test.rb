require "test_helper"

class Presenters::SeatTest < ActiveSupport::TestCase
  test "token takeover dismisses a pending claim" do
    night = game_sessions(:david)
    Presenters::Seat.call(night:, device_token: "old-holder")
    claim = Presenters::Claim.call(night: night.reload, device_token: "claimer", name: "Ana")
    assert claim.pending?

    Presenters::Seat.call(night: night.reload, device_token: "new-holder", clear_pending: true)
    assert claim.reload.refused?
    assert night.reload.presenter_held_by?("new-holder")
  end

  test "needs a device" do
    assert_raises(ArgumentError) { Presenters::Seat.call(night: game_sessions(:david)) }
  end
end
