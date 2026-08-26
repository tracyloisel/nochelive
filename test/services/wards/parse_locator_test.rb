require "test_helper"

class Wards::ParseLocatorTest < ActiveSupport::TestCase
  setup do
    @payload = JSON.parse(file_fixture("meetinghouses.json").read)
  end

  test "extracts congregations and skips temples and stakes" do
    rows = Wards::ParseLocator.call(@payload)
    names = rows.map { |row| row[:name] }

    assert_includes names, "Benidorm Ward"
    assert_includes names, "Valencia 1st Ward"
    assert_includes names, "Jardim Ângela Ward"
    assert_includes names, "Capão Redondo Branch"
    assert_not_includes names, "Alicante Spain Stake"
    assert_not_includes names, "Madrid Spain Temple"
  end

  test "fills chapel place and stake for Benidorm" do
    row = Wards::ParseLocator.call(@payload).find { |item| item[:church_unit_id] == "unit-benidorm" }

    assert_equal "ward", row[:unit_kind]
    assert_equal "ES", row[:country_code]
    assert_equal "Spain", row[:country_name]
    assert_equal "Benidorm", row[:city]
    assert_match(/Alfonso Puchades/, row[:chapel_address])
    assert_equal "Alicante Spain Stake", row[:stake_name]
    assert_in_delta 38.5412, row[:latitude], 0.001
  end

  test "marks Brazilian branch as branch" do
    row = Wards::ParseLocator.call(@payload).find { |item| item[:church_unit_id] == "unit-sp-branch" }
    assert_equal "branch", row[:unit_kind]
    assert_equal "BR", row[:country_code]
  end
end
