require "test_helper"

class Wards::QueryLocatorTest < ActiveSupport::TestCase
  test "maps a Church Maps unit without contact fields" do
    row = JSON.parse(file_fixture("maps_ward_benidorm.json").read).first
    attrs = Wards::QueryLocator.attrs_from(row)

    assert_equal "333239", attrs[:church_unit_id]
    assert_equal "Benidorm Branch", attrs[:name]
    assert_equal "branch", attrs[:unit_kind]
    assert_equal "ES", attrs[:country_code]
    assert_equal "Benidorm", attrs[:city]
    assert_match(/Alfonso Puchades/, attrs[:chapel_address])
    assert_equal "Elche Spain Stake", attrs[:stake_name]
    assert_in_delta 38.54202, attrs[:latitude], 0.0001
    assert_in_delta(-0.12452, attrs[:longitude], 0.0001)
    assert_nil attrs[:contact]
  end

  test "collapses extra spaces in congregation names" do
    attrs = Wards::QueryLocator.attrs_from(
      "type" => "WARD",
      "name" => "Murcia  1st Ward",
      "identifiers" => { "unitNumber" => 1 }
    )
    assert_equal "Murcia 1st Ward", attrs[:name]
  end

  test "skips stakes and meetinghouses" do
    assert_nil Wards::QueryLocator.attrs_from("type" => "STAKE", "name" => "Elche Spain Stake", "id" => "1")
    assert_nil Wards::QueryLocator.attrs_from("type" => "MEETINGHOUSE", "id" => "500-01", "name" => "Chapel")
  end

  test "does not hit the Church from CI" do
    Wards::QueryLocator.forced_details = nil
    assert_empty Wards::QueryLocator.call(query: "Madrid")
    assert_empty Wards::QueryLocator.near(latitude: 40.4, longitude: -3.7)
    assert_nil Wards::QueryLocator.details(church_unit_id: "333239")
  end

  test "walks Church text search through a fake transport" do
    units = file_fixture("maps_ward_madrid.json").read
    Wards::QueryLocator.transport = lambda do |url, _params|
      url.include?("/locations/search") ? units : "[]"
    end

    rows = Wards::QueryLocator.call(query: "Madrid")
    assert_equal 1, rows.size
    assert_equal "999001", rows.first[:church_unit_id]
    assert_equal "Madrid 1st Ward", rows.first[:name]
  end

  test "reads the assigned ward from an identify chapel" do
    payload = file_fixture("maps_identify_benidorm.json").read
    Wards::QueryLocator.transport = lambda do |url, _params|
      url.include?("identify") ? payload : "[]"
    end

    rows = Wards::QueryLocator.near(latitude: 38.54, longitude: -0.12)
    assert_equal 1, rows.size
    assert_equal "333239", rows.first[:church_unit_id]
    assert_equal "Benidorm Branch", rows.first[:name]
  end
end
