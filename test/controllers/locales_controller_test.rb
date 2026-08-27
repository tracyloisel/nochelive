require "test_helper"

class LocalesControllerTest < ActionDispatch::IntegrationTest
  test "a visitor can switch language from home" do
    patch locale_path, params: { locale: "fr" }
    follow_redirect!

    assert_equal "fr", cookies[:noche_locale]
    assert_select "html[lang=fr]"
    assert_select "#street_world"
    assert_select "nav.home-menu"
    assert_select ".chrome-drawer a", text: /paroisse/
    assert_select ".chrome-drawer a", text: /Qui sommes-nous/
    assert_select ".chrome-drawer a", text: /Chercher/
    assert_select ".chrome-drawer a", text: /Jouer pour une autre paroisse/, count: 0
    assert_select ".home-search", count: 0
    assert_select ".chrome-tools", count: 0
    assert_select ".chrome-drawer .mute"
    assert_select ".chrome-drawer .mute .word", text: "Activé"
    assert_select ".home-menu-kicker", text: /Paroisse/
    assert_select ".home-menu-kicker", text: /Église de Jésus-Christ/
    assert_select ".chrome-drawer .lang-switch.is-drawer"
    assert_select ".chrome-drawer .lang-switch.is-drawer > summary .picto-flag-fr"
    assert_select ".chrome-drawer .lang-opt.is-on .picto-flag-fr"
    assert_select ".chrome-drawer .lang-opt .picto-flag-es"
    assert_select ".chrome-drawer .lang-opt .picto-flag-pt"
    assert_select ".chrome-drawer .lang-opt .picto-flag-en"
    assert_select ".chrome-drawer .lang-opt .lang-name", text: "Español"
    assert_select ".chrome-drawer .lang-opt .lang-name", text: "Português"
    assert_select ".chrome-drawer .lang-opt .lang-name", text: "Français"
    assert_select ".chrome-drawer .lang-opt .lang-name", text: "English"

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
    assert_select ".chrome-tools .mute + .lang-switch"
    assert_select ".lang-switch > summary .picto-flag-en"
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
    assert_select ".chrome-tools .mute + .lang-switch"
    assert_select ".lang-switch > summary .picto-flag-fr"
  end
end
