require "test_helper"

class Wards::OpenTest < ActiveSupport::TestCase
  test "opens a rama with the admin secret" do
    ward = Wards::Open.call(code: "RAMA", token: "rama-demo")
    assert_equal wards(:demo), ward
  end

  test "rejects a bad secret" do
    error = assert_raises(People::Error) { Wards::Open.call(code: "RAMA", token: "nope") }
    assert_equal :token, error.code
  end
end
