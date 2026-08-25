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
end
