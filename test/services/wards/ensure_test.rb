require "test_helper"

class Wards::EnsureTest < ActiveSupport::TestCase
  test "returns a rama already stored by church unit id" do
    ward = extra_ward(21, listed: true, church_unit_id: "999001", city: "Madrid")
    found = Wards::Ensure.call(church_unit_id: "WARD:999001")

    assert_equal ward, found
  end

  test "creates a listed rama from the locator on first pick" do
    Wards::QueryLocator.forced_details = Wards::QueryLocator.attrs_from(
      JSON.parse(file_fixture("maps_ward_madrid.json").read).first
    )

    assert_difference -> { Ward.listed.count }, 1 do
      ward = Wards::Ensure.call(church_unit_id: "999001")
      assert ward.listed?
      assert_equal "Madrid 1st Ward", ward.name
      assert_equal "999001", ward.church_unit_id
      assert_in_delta 40.4168, ward.latitude, 0.001
      assert_equal 0, ward.people.count
    end
  end

  test "merges Benidorm into RAMA instead of a second row" do
    Wards::QueryLocator.forced_details = Wards::QueryLocator.attrs_from(
      JSON.parse(file_fixture("maps_ward_benidorm.json").read).first
    )

    ward = Wards::Ensure.call(church_unit_id: "333239")
    demo = wards(:demo).reload

    assert_equal demo, ward
    assert_equal "RAMA", demo.code
    assert_equal "Rama Benidorm", demo.name
    assert_equal "333239", demo.church_unit_id
    assert_equal 1, Ward.where("LOWER(city) = ?", "benidorm").count
  end

  test "rejects a unit the locator does not know" do
    error = assert_raises(People::Error) { Wards::Ensure.call(church_unit_id: "nope") }
    assert_equal :missing, error.code
  end
end
