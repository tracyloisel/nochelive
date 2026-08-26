require "test_helper"

class Wards::EnterTest < ActiveSupport::TestCase
  test "enters a rama by code" do
    assert_equal wards(:demo), Wards::Enter.call(code: "RAMA")
  end

  test "rejects a missing rama" do
    error = assert_raises(People::Error) { Wards::Enter.call(code: "NOPE") }
    assert_equal :missing, error.code
  end

  test "creates from church unit id when the rama is not stored yet" do
    Wards::QueryLocator.forced_details = Wards::QueryLocator.attrs_from(
      JSON.parse(file_fixture("maps_ward_madrid.json").read).first
    )

    ward = Wards::Enter.call(church_unit_id: "999001")
    assert_equal "Madrid 1st Ward", ward.name
    assert ward.listed?
  end
end
