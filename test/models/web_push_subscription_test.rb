require "test_helper"

class WebPushSubscriptionTest < ActiveSupport::TestCase
  test "encrypts the endpoint and browser keys at rest" do
    row = web_push_subscriptions(:carmen_phone_push)

    assert_equal "https://push.example.test/carmen", row.endpoint
    assert_equal "carmen-p256dh", row.p256dh
    assert_equal "carmen-auth", row.auth
    refute_includes row.endpoint_ciphertext, "push.example.test"
    refute_includes row.p256dh_ciphertext, "carmen-p256dh"
  end

  test "rejects a duplicated endpoint digest and invalid timezone" do
    original = web_push_subscriptions(:carmen_phone_push)
    duplicate = original.dup
    duplicate.person = people(:pili)
    duplicate.time_zone = "Mars/Olympus"

    refute duplicate.valid?
    assert duplicate.errors[:endpoint_digest].any?
    assert duplicate.errors[:time_zone].any?
  end
end
