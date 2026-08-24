require "test_helper"

class Presenter::PeopleControllerTest < ActionDispatch::IntegrationTest
  test "presenter links a guest to a ficha" do
    night = game_sessions(:elias)
    player = Players::Join.call(
      night:,
      name: "Carmen",
      role: "participant",
      location: "room",
      device_token: "lost-phone",
      avatar_key: "delfin"
    )
    sign_in_presenter(night)
    post presenter_person_link_path(night.code, people(:carmen_garcia)), params: { player_id: player.id }
    assert_redirected_to presenter_console_path(night.code)
    assert_equal people(:carmen_garcia), player.reload.person
  end

  test "presenter can pick a ficha from the list" do
    night = game_sessions(:elias)
    player = Players::Join.call(
      night:,
      name: "Huésped",
      role: "participant",
      location: "room",
      device_token: "guest-phone",
      avatar_key: "gato"
    )
    sign_in_presenter(night)
    post presenter_people_link_path(night.code), params: { player_id: player.id, person_id: people(:pili).id }
    assert_redirected_to presenter_console_path(night.code)
    assert_equal people(:pili), player.reload.person
  end
end
