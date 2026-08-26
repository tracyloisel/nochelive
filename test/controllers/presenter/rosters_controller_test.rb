require "test_helper"

class Presenter::RostersControllerTest < ActionDispatch::IntegrationTest
  setup { @night = game_sessions(:elias) }

  test "presenter sees the night roster and can name missionaries" do
    sign_in_presenter(@night)
    get presenter_roster_path(@night.code)
    assert_response :success
    assert_select "body.is-paper-hall"
    assert_select "#night_roster.hall-paper"
    assert_select ".hall-sheet"
    assert_select ".hall-still"
    assert_select "h1", "Lista de esta noche"
    assert_select ".lang-assign"
    assert_select ".play-reel", count: 0
    assert_select ".gate", count: 0

    post presenter_missionaries_path(@night.code), params: { name: "Élder Soto" }
    assert_redirected_to presenter_roster_path(@night.code)
    assert_equal "Élder Soto", @night.missionaries.last.name

    delete presenter_missionary_path(@night.code, @night.missionaries.last)
    assert_redirected_to presenter_roster_path(@night.code)
    assert_equal 0, @night.missionaries.count
  end
end
