require "test_helper"

class Presenter::LocalesControllerTest < ActionDispatch::IntegrationTest
  test "presenter sets language for a person in the night" do
    night = game_sessions(:david)
    sign_in_presenter(night)
    player = players(:lucia)

    patch presenter_player_locale_path(night.code, player), params: { locale: "pt-BR" }
    follow_redirect!

    assert_equal "pt-BR", player.reload.locale
  end

  test "presenter sets language for a spectator" do
    night = game_sessions(:david)
    sign_in_presenter(night)
    spectator = players(:publico)

    patch presenter_player_locale_path(night.code, spectator), params: { locale: "fr" }
    follow_redirect!

    assert_equal "fr", spectator.reload.locale
  end

  test "presenter list offers a language picker per person" do
    night = game_sessions(:david)
    sign_in_presenter(night)

    get presenter_roster_path(night.code)

    assert_select ".lang-assign"
    assert_select "option[value=fr]"
  end
end
