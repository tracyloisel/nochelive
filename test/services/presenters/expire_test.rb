require "test_helper"

class Presenters::ExpireTest < ActiveSupport::TestCase
  test "no-ops when missing or still waiting" do
    assert_nil Presenters::Expire.call(claim: nil)

    night = game_sessions(:david)
    Presenters::Seat.call(night:, device_token: "holder")
    claim = Presenters::Claim.call(night: night.reload, device_token: "claimer", name: "Ana")
    assert_equal "pending", Presenters::Expire.call(claim: claim).status
  end

  test "grant is idempotent after the wait" do
    night = game_sessions(:david)
    Presenters::Seat.call(night:, device_token: "holder")
    claim = Presenters::Claim.call(night: night.reload, device_token: "claimer", name: "Ana")
    travel PresenterClaim::TIMEOUT.seconds + 1
    first = Presenters::Grant.call(claim: claim)
    second = Presenters::Grant.call(claim: claim)
    assert first.granted?
    assert_equal first.id, second.id
    assert night.reload.presenter_held_by?("claimer")
  end
end
