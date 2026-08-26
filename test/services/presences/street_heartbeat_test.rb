require "test_helper"

class Presences::StreetHeartbeatTest < ActiveSupport::TestCase
  test "marks the person's device live" do
    device = person_devices(:pili_tablet)
    device.update_column(:last_seen_at, 2.minutes.ago)

    Presences::StreetHeartbeat.call(person: people(:pili), device_token: device.device_token)

    assert device.reload.live?
  end

  test "ignores a token that is not this person's device" do
    device = person_devices(:pili_tablet)
    device.update_column(:last_seen_at, 2.minutes.ago)

    Presences::StreetHeartbeat.call(person: people(:pili), device_token: "other-phone")

    assert_not device.reload.live?
  end
end
