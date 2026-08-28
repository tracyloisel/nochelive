require "test_helper"

class PersonDeviceTest < ActiveSupport::TestCase
  test "fixture device belongs to pili" do
    assert_equal people(:pili), person_devices(:pili_tablet).person
  end

  test "live state follows the realtime registry, not last_seen_at" do
    device = person_devices(:pili_tablet)
    entry = mark_person_online(device.person)
    assert device.live?

    Presences::Registry.leave(entry)
    assert_not device.live?
  end
end
