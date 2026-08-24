require "test_helper"

class PresenterClaimTest < ActiveSupport::TestCase
  test "pending claim needs a name and an expiry" do
    claim = PresenterClaim.new(game_session: game_sessions(:david), device_digest: "abc", status: "pending")
    assert_not claim.valid?
    claim.name = "Ana"
    claim.expires_at = 1.minute.from_now
    assert claim.valid?
    assert claim.pending?
    assert_not claim.expired?
  end
end
