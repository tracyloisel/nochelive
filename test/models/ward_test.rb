require "test_helper"

class WardTest < ActiveSupport::TestCase
  test "scripture circles are open by default" do
    assert_equal "active", Ward.column_defaults.fetch("scripture_circle_mode")
  end

  test "demo rama has a matching secret" do
    assert wards(:demo).admin_token_matches?("rama-demo")
    assert_not wards(:demo).admin_token_matches?("nope")
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

  test "assigns a stable public slug and qualifies city collisions without using the address" do
    first = extra_ward(7, city: "São Paulo", name: "São Paulo Interlagos Ward", chapel_address: "Rua das Flores, 99")
    second = extra_ward(8, city: "São Paulo", name: "Capão Redondo Branch", chapel_address: "Avenida do Sol, 42")

    assert_equal "sao-paulo", first.public_slug
    assert_equal "sao-paulo-capao-redondo", second.public_slug
    refute_includes second.public_slug, "avenida"

    second.city = "Embu das Artes"
    second.name = "Capão Redondo Branch Renamed"
    second.save!
    assert_equal "sao-paulo-capao-redondo", second.reload.public_slug
  end

  test "normalizes an explicit public slug and rejects later changes" do
    ward = extra_ward(9, public_slug: "  Valencia Norte  ")

    assert_equal "valencia-norte", ward.public_slug
    ward.public_slug = "valencia-sur"
    assert_not ward.valid?
    assert ward.errors.of_kind?(:public_slug, :readonly)
  end

  test "reserves room for a unique qualifier when a city fills the slug limit" do
    slug = Ward.public_slug_with_qualifier("a" * Ward::PUBLIC_SLUG_MAX, "second")

    assert_equal "#{"a" * 153}-second", slug
    assert_equal Ward::PUBLIC_SLUG_MAX, slug.length
  end

  test "reads Sunday worship hours from the official locator payload" do
    ward = wards(:demo)
    ward.locator_payload = {
      "hours" => {
        "primary" => { "hour" => { "code" => "10:00:00" } },
        "days" => [
          { "day" => { "code" => "SUNDAY" }, "hours" => { "ranges" => [ { "start" => { "code" => "10:00:00" }, "finish" => { "code" => "12:00:00" } } ] } }
        ]
      }
    }

    assert_equal [
      { "label_key" => "sacrament_meeting", "time" => "10:00" },
      { "label_key" => "sunday_meetings", "time" => "10:00–12:00" }
    ], ward.sunday_schedule
  end

  test "falls back to the compact Church locator hours code" do
    ward = wards(:demo)
    ward.locator_payload = { "hours" => { "code" => "Su 09:30-11:30" } }

    assert_equal [ "09:30", "09:30–11:30" ], ward.sunday_schedule.pluck("time")
  end
end
