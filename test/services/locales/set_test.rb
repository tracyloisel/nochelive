require "test_helper"

class Locales::SetTest < ActiveSupport::TestCase
  test "updates the player and live seats on the same person" do
    player = players(:lucia)
    Locales::Set.call(locale: "fr", player: player)

    assert_equal "fr", player.reload.locale
  end

  test "stores presenter locale on the night" do
    night = game_sessions(:david)
    Locales::Set.call(locale: "en", night: night, presenter: true)

    assert_equal "en", night.reload.presenter_locale
  end

  test "updates a person and every live seat linked to that profile" do
    person = people(:pili)
    player = players(:lucia)
    player.update!(person: person, locale: "es")

    Locales::Set.call(locale: "pt-BR", person: person)

    assert_equal "pt-BR", person.reload.locale
    assert_equal "pt-BR", player.reload.locale
  end
end
