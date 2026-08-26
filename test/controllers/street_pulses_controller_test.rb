require "test_helper"

class StreetPulsesControllerTest < ActionDispatch::IntegrationTest
  test "pulse frame is a fragment with house numbers" do
    get street_pulse_path, headers: { "Turbo-Frame" => "street_pulse" }

    assert_response :success
    assert_select "turbo-frame#street_pulse a.street-pulse[href=?][data-turbo-frame=?]", platform_stats_path, "_top"
    assert_select "a.street-pulse[aria-label=?]", I18n.t("stats.menu")
    assert_select ".street-pulse-month"
    assert_select ".street-pulse-live"
    assert_select "body", count: 0
    assert_select ".street-play-cta", count: 0
    assert_match(/no-cache|no-store|max-age=0/, response.headers["Cache-Control"].to_s)
  end

  test "pulse numbers move when someone comes online" do
    PersonDevice.update_all(last_seen_at: 1.hour.ago)
    Player.update_all(last_seen_at: 1.hour.ago)

    get street_pulse_path, headers: { "Turbo-Frame" => "street_pulse" }
    assert_select ".street-pulse[data-pulse-online=?]", "0"

    person_devices(:pili_tablet).update_column(:last_seen_at, Time.current)

    get street_pulse_path, headers: { "Turbo-Frame" => "street_pulse" }
    assert_select ".street-pulse[data-pulse-online=?]", "1"
  end
end
