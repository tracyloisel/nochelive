require "test_helper"

class LocalesControllerTest < ActionDispatch::IntegrationTest
  test "a visitor can switch language from home" do
    patch locale_path, params: { locale: "fr" }
    follow_redirect!

    assert_equal "fr", cookies[:noche_locale]
    assert_select "html[lang=fr]"
    assert_select "#street_world"
    assert_select "nav.home-menu"
    assert_select ".chrome-drawer a", text: /Ma paroisse/
    assert_select ".chrome-drawer a", text: /About us/
    assert_select ".chrome-drawer a.home-menu-adventure[href=?]", street_map_path, text: /Aventure/
    assert_select ".chrome-drawer a[href='#{street_leaderboard_path}']", text: "Leaderboard"
    assert_select ".chrome-drawer a", text: /Jouer pour une autre paroisse/, count: 0
    assert_select ".home-search", count: 0
    assert_select ".chrome-tools", count: 0
    assert_select ".chrome-drawer .mute"
    assert_select ".chrome-drawer .mute .word", text: "Activé"
    assert_select ".home-menu-kicker", text: /Écritures & communauté/
    assert_select ".home-menu-kicker", text: /Jeu & social/
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

  test "a player can switch language during a Noche Live" do
    night = game_sessions(:david)
    sign_in_as_participant(night, name: "Sofía", team: teams(:leones))

    patch night_locale_path(night.code), params: { locale: "en" }
    follow_redirect!

    player = night.players.find_by!(name: "Sofía")
    assert_equal "en", player.reload.locale
    get night_path(night.code)
    assert_select "html[lang=en]"
    assert_select ".noche-live"
  end

end
