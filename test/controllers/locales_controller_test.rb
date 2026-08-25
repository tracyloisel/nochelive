require "test_helper"

class LocalesControllerTest < ActionDispatch::IntegrationTest
  test "a visitor can switch language from home" do
    patch locale_path, params: { locale: "fr" }
    follow_redirect!

    assert_equal "fr", cookies[:noche_locale]
    assert_select "html[lang=fr]"
    assert_select "details.home-menu"
    assert_select "details.home-menu a", text: /paroisse/
    assert_select ".home-doors a", text: /Qui sommes-nous/
    assert_select ".home-doors a", text: /Chercher/
    assert_select "h2", text: /Prochainement/
    assert_select ".home-search", count: 0
    assert_select ".lang-switch"
  end

  test "a player can switch language during a round" do
    night = game_sessions(:david)
    round_runs(:salomon).update_column(:opened_at, Time.current)
    sign_in_as_participant(night, name: "Sofía", team: teams(:leones))

    patch night_locale_path(night.code), params: { locale: "en" }
    follow_redirect!

    player = night.players.find_by!(name: "Sofía")
    assert_equal "en", player.reload.locale
    get night_play_path(night.code)
    assert_select "html[lang=en]"
    assert_select ".lang-switch"
    assert_select ".prompt", text: /Solomon|ask for/
  end

  test "presenter can switch language from the console" do
    night = game_sessions(:david)
    sign_in_presenter(night)

    patch night_locale_path(night.code), params: { locale: "fr" }
    follow_redirect!

    assert_equal "fr", night.reload.presenter_locale
    get presenter_console_path(night.code)
    assert_select "html[lang=fr]"
    assert_select ".lang-switch"
  end
end
