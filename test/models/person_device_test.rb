require "test_helper"

class PersonDeviceTest < ActiveSupport::TestCase
  test "fixture device belongs to pili" do
    assert_equal people(:pili), person_devices(:pili_tablet).person
  end
end
