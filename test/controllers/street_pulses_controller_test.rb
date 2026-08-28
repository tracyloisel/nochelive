require "test_helper"

class StreetPulsesControllerTest < ActionDispatch::IntegrationTest
  test "pulse frame is a fragment with house numbers" do
    get street_pulse_path, headers: { "Turbo-Frame" => "street_pulse" }

    assert_response :success
    assert_select "turbo-frame#street_pulse .street-pulse"
    assert_select ".street-pulse-month"
    assert_select ".street-pulse-live"
    assert_select "body", count: 0
    assert_select ".street-play-cta", count: 0
    assert_match(/max-age=15/, response.headers["Cache-Control"].to_s)
    assert_match(/public/, response.headers["Cache-Control"].to_s)
  end

  test "pulse numbers move when someone comes online" do
    get street_pulse_path, headers: { "Turbo-Frame" => "street_pulse" }
    assert_select ".street-pulse[data-pulse-online=?]", "0"

    mark_person_online(people(:pili))

    get street_pulse_path, headers: { "Turbo-Frame" => "street_pulse" }
    assert_select ".street-pulse[data-pulse-online=?]", "1"
  end
end
