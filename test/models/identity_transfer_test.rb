require "test_helper"

class IdentityTransferTest < ActiveSupport::TestCase
  test "a token can be consumed only once" do
    token = IdentityTransfer.issue!("signed" => { "noche_device" => "device-token" })

    assert_equal "device-token", IdentityTransfer.consume!(token).dig("signed", "noche_device")
    assert_raises(IdentityTransfer::InvalidToken) { IdentityTransfer.consume!(token) }
  end

  test "an expired token cannot be consumed" do
    token = IdentityTransfer.issue!("signed" => { "noche_device" => "device-token" })
    IdentityTransfer.update_all(expires_at: 1.minute.ago)

    assert_raises(IdentityTransfer::InvalidToken) { IdentityTransfer.consume!(token) }
  end

  test "the database does not store the token or payload in plaintext" do
    token = IdentityTransfer.issue!("signed" => { "noche_device" => "sensitive-device-token" })
    transfer = IdentityTransfer.last

    refute_equal token, transfer.token_digest
    refute_includes transfer.encrypted_payload, "sensitive-device-token"
  end
end
