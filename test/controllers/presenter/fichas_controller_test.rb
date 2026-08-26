require "test_helper"

class Presenter::FichasControllerTest < ActionDispatch::IntegrationTest
  test "presenter opens the ficha desk from the night" do
    night = game_sessions(:elias)
    sign_in_presenter(night)
    get presenter_fichas_path(night.code)
    assert_response :success
    assert_select "body.is-paper-hall"
    assert_select "#ficha_index.hall-paper"
    assert_select ".hall-sheet"
    assert_select ".hall-still"
    assert_select "h1", "Fichas de la rama"
    assert_select ".play-reel", count: 0
    get presenter_ficha_path(night.code, people(:carmen_garcia))
    assert_response :success
    assert_select ".year-shout", "1833"
  end
end
