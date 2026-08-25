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
end
