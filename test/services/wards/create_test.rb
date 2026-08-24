require "test_helper"

class Wards::CreateTest < ActiveSupport::TestCase
  test "creates a rama with a presenter token" do
    ward = Wards::Create.call(name: "Madrid Centro")
    assert_equal "Madrid Centro", ward.name
    assert ward.presenter_token.present?
    assert ward.presenter_token_matches?(ward.presenter_token)
  end

  test "rejects a blank name" do
    error = assert_raises(People::Error) { Wards::Create.call(name: "  ") }
    assert_equal :blank, error.code
  end
end
