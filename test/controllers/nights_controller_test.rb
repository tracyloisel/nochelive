require "test_helper"

class NightsControllerTest < ActionDispatch::IntegrationTest
  test "canonical URL renders the scheduled registration experience" do
    get night_path(game_sessions(:elias).code)

    assert_response :success
    assert_select ".noche-live-status.is-scheduled"
    assert_select ".home-menu.is-hud[data-hud-theme='celestial-dark']"
    assert_select ".noche-live-rama", text: /#{Regexp.escape(game_sessions(:elias).ward.name)}/
    assert_select "a.noche-live-join[href=?]", night_name_path(game_sessions(:elias).code), text: /#{Regexp.escape(I18n.t("nights.register"))}/
    assert_select ".noche-live-readings a"
  end

  test "canonical URL renders Watch during the live hour" do
    night = game_sessions(:david)
    night.update_columns(starts_at: 5.minutes.ago, ends_at: 55.minutes.from_now, status: "playing")

    get night_path(night.code)

    assert_response :success
    assert_select ".noche-watch-grid"
    assert_select ".noche-watch-ranking"
    assert_select ".noche-watch-progress"
    assert_select ".noche-watch-events"
    assert_select "#live_event_tile"
    assert_select ".noche-live-qr svg"
  end
end
