require "test_helper"

class Presenters::ResolveTest < ActiveSupport::TestCase
  setup do
    @night = game_sessions(:david)
    @holder = "holder-phone"
    @claimant = "claimant-phone"
    Presenters::Seat.call(night: @night, device_token: @holder)
    @claim = Presenters::Claim.call(night: @night.reload, device_token: @claimant, name: "Lucía")
  end

  test "holder can keep the desk" do
    Presenters::Resolve.call(night: @night, claim: @claim, decision: "refuse", holder_token: @holder)
    assert @claim.reload.refused?
    assert @night.reload.presenter_held_by?(@holder)
  end

  test "holder can cede" do
    Presenters::Resolve.call(night: @night, claim: @claim, decision: "grant", holder_token: @holder)
    assert @claim.reload.granted?
    assert @night.reload.presenter_held_by?(@claimant)
  end

  test "holder can ban that phone for this night" do
    Presenters::Resolve.call(night: @night, claim: @claim, decision: "block", holder_token: @holder)
    assert @claim.reload.blocked?
    assert @night.presenter_blocks.exists?(device_digest: GameSession.digest_token(@claimant))

    error = assert_raises(People::Error) {
      Presenters::Claim.call(night: @night.reload, device_token: @claimant, name: "Lucía")
    }
    assert_equal :blocked, error.code
    assert @night.reload.presenter_held_by?(@holder)
  end

  test "refused claimant may ask again" do
    Presenters::Resolve.call(night: @night, claim: @claim, decision: "refuse", holder_token: @holder)
    again = Presenters::Claim.call(night: @night.reload, device_token: @claimant, name: "Lucía")
    assert again.pending?
    assert_not_equal @claim.id, again.id
  end

  test "stranger cannot resolve" do
    error = assert_raises(People::Error) {
      Presenters::Resolve.call(night: @night, claim: @claim, decision: "refuse", holder_token: "other-phone")
    }
    assert_equal :forbidden, error.code
    assert @claim.reload.pending?

    error = assert_raises(People::Error) {
      Presenters::Resolve.call(night: @night, claim: @claim, decision: "grant", holder_token: "other-phone")
    }
    assert_equal :forbidden, error.code
  end

  test "already resolved cannot be refused again" do
    Presenters::Resolve.call(night: @night, claim: @claim, decision: "refuse", holder_token: @holder)
    error = assert_raises(People::Error) {
      Presenters::Resolve.call(night: @night, claim: @claim, decision: "refuse", holder_token: @holder)
    }
    assert_equal :missing, error.code
  end

  test "missing claim is rejected" do
    error = assert_raises(People::Error) {
      Presenters::Resolve.call(night: @night, claim: nil, decision: "refuse", holder_token: @holder)
    }
    assert_equal :missing, error.code
  end

  test "unknown decision is rejected" do
    error = assert_raises(People::Error) {
      Presenters::Resolve.call(night: @night, claim: @claim, decision: "shrug", holder_token: @holder)
    }
    assert_equal :missing, error.code
  end
end
