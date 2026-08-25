require "test_helper"

class Wards::EnterTest < ActiveSupport::TestCase
  test "enters a rama by code" do
    assert_equal wards(:demo), Wards::Enter.call(code: "RAMA")
  end

  test "rejects a missing rama" do
    error = assert_raises(People::Error) { Wards::Enter.call(code: "NOPE") }
    assert_equal :missing, error.code
  end
end
