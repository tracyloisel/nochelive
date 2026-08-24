require "test_helper"

class Presenters::ClaimTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @night = game_sessions(:david)
    @holder = "holder-phone"
    @claimant = "claimant-phone"
  end

  test "empty desk seats at once" do
    assert_equal :seated, Presenters::Claim.call(night: @night, device_token: @holder, name: "Ana")
    assert @night.reload.presenter_held_by?(@holder)
    assert_nil @night.pending_presenter_claim
  end

  test "same device as holder seats again" do
    Presenters::Seat.call(night: @night, device_token: @holder)
    assert_equal :seated, Presenters::Claim.call(night: @night.reload, device_token: @holder, name: "Ana")
  end

  test "another device waits and names the person" do
    Presenters::Seat.call(night: @night, device_token: @holder)

    assert_enqueued_with(job: PresenterClaimExpiryJob) do
      claim = Presenters::Claim.call(night: @night.reload, device_token: @claimant, name: "Lucía Soto")
      assert claim.pending?
      assert_equal "Lucía Soto", claim.name
      assert_in_delta PresenterClaim::TIMEOUT, (claim.expires_at - Time.current), 2
    end

    assert_equal "Lucía Soto", @night.reload.pending_presenter_claim.name
  end

  test "same claimant does not reset the wait" do
    Presenters::Seat.call(night: @night, device_token: @holder)
    first = Presenters::Claim.call(night: @night.reload, device_token: @claimant, name: "Uno")
    travel 20.seconds
    second = Presenters::Claim.call(night: @night.reload, device_token: @claimant, name: "Dos")
    assert_equal first.id, second.id
    assert_equal "Uno", second.name
  end

  test "a third phone cannot jump the queue" do
    Presenters::Seat.call(night: @night, device_token: @holder)
    Presenters::Claim.call(night: @night.reload, device_token: @claimant, name: "Lucía")

    error = assert_raises(People::Error) {
      Presenters::Claim.call(night: @night.reload, device_token: "third-phone", name: "Pedro")
    }
    assert_equal :busy, error.code
  end

  test "blank token is rejected" do
    error = assert_raises(People::Error) {
      Presenters::Claim.call(night: @night, device_token: " ", name: "Ana")
    }
    assert_equal :missing, error.code
  end

  test "silence after a minute grants the desk" do
    Presenters::Seat.call(night: @night, device_token: @holder)
    claim = Presenters::Claim.call(night: @night.reload, device_token: @claimant, name: "Lucía")

    Presenters::Expire.call(claim: claim)
    assert claim.reload.pending?

    travel PresenterClaim::TIMEOUT.seconds + 1
    Presenters::Expire.call(claim: claim)
    assert claim.reload.granted?
    assert @night.reload.presenter_held_by?(@claimant)
    assert_not @night.presenter_held_by?(@holder)
  end
end
