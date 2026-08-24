require "test_helper"

class WardTest < ActiveSupport::TestCase
  test "demo rama has a matching secret" do
    assert wards(:demo).presenter_token_matches?("rama-demo")
    assert_not wards(:demo).presenter_token_matches?("nope")
  end
end
