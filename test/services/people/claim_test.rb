require "test_helper"

class People::ClaimTest < ActiveSupport::TestCase
  setup do
    People::Claim.reset_attempts!
    @ward = wards(:demo)
    @person = people(:carmen_garcia)
  end

  teardown { People::Claim.reset_attempts! }

  test "attaches the device when the year matches" do
    People::Claim.call(ward: @ward, person: @person, favorite_year: 1833, device_token: "phone-2")
    assert PersonDevice.exists?(person: @person, device_token: "phone-2")
  end

  test "rejects a wrong year" do
    error = assert_raises(People::Error) do
      People::Claim.call(ward: @ward, person: @person, favorite_year: 1, device_token: "phone-2")
    end
    assert_equal :year, error.code
  end

  test "locks after too many misses" do
    8.times do
      assert_raises(People::Error) do
        People::Claim.call(ward: @ward, person: @person, favorite_year: 1, device_token: "brute")
      end
    end
    error = assert_raises(People::Error) do
      People::Claim.call(ward: @ward, person: @person, favorite_year: 1833, device_token: "brute")
    end
    assert_equal :locked, error.code
  end
end
