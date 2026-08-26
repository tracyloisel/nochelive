require "test_helper"

class PersonDeviceTest < ActiveSupport::TestCase
  test "fixture device belongs to pili" do
    assert_equal people(:pili), person_devices(:pili_tablet).person
  end

  test "live window follows last_seen_at" do
    device = person_devices(:pili_tablet)
    device.update_column(:last_seen_at, Time.current)
    assert device.live?

    device.update_column(:last_seen_at, 1.minute.ago)
    assert_not device.live?
  end
end
