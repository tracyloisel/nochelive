require "test_helper"

class WardTest < ActiveSupport::TestCase
  test "demo rama has a matching secret" do
    assert wards(:demo).presenter_token_matches?("rama-demo")
    assert_not wards(:demo).presenter_token_matches?("nope")
  end

  test "Benidorm chapel pin points at Alfonso Puchades" do
    ward = wards(:demo)
    assert_equal "Rama Benidorm", ward.name
    assert_equal "Benidorm", ward.city
    assert_equal "ES", ward.country_code
    assert ward.listed?
    assert_not wards(:blank).listed?
    assert_match(/Alfonso Puchades/, ward.maps_query)
    assert_match(%r{google.com/maps/search}, ward.maps_url)
    assert_match(/Alfonso/, ward.maps_url)
    assert_match(/Benidorm/, ward.maps_url)
  end

  test "accepts any ISO country and a long official name" do
    ward = extra_ward(9, listed: true, country_code: "JP", country_name: "Japan", name: "T" * Ward::NAME_MAX)
    assert_equal "JP", ward.country_code
    assert_equal Ward::NAME_MAX, ward.name.length
    assert_match(/\A[A-Z0-9]{5}\z/, Ward.generate_import_code)
  end
end
