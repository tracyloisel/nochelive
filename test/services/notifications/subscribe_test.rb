require "test_helper"

class Notifications::SubscribeTest < ActiveSupport::TestCase
  def payload(endpoint = "https://push.example.test/new")
    { endpoint:, keys: { p256dh: "new-p256dh", auth: "new-auth" } }
  end

  test "stores a subscription for one ficha and normalizes an invalid timezone" do
    row = Notifications::Subscribe.call(
      person: people(:pili), device_token: "pili-tablet", subscription: payload,
      locale: :fr, time_zone: "Not/AZone", user_agent_family: "Safari"
    )

    assert_equal people(:pili), row.person
    assert_equal "UTC", row.time_zone
    assert_equal "https://push.example.test/new", row.endpoint
  end

  test "requires explicit confirmation before reassigning a shared browser" do
    endpoint = web_push_subscriptions(:carmen_phone_push).endpoint

    error = assert_raises(Notifications::Subscribe::Error) do
      Notifications::Subscribe.call(
        person: people(:pili), device_token: "pili-tablet", subscription: payload(endpoint),
        locale: :fr, time_zone: "Europe/Paris"
      )
    end
    assert_equal :reassignment_required, error.code

    row = Notifications::Subscribe.call(
      person: people(:pili), device_token: "pili-tablet", subscription: payload(endpoint),
      locale: :fr, time_zone: "Europe/Paris", reassign: true
    )
    assert_equal people(:pili), row.reload.person
  end
end
