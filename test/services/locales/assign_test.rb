require "test_helper"

class Locales::AssignTest < ActiveSupport::TestCase
  test "presenter sets a player's language" do
    player = players(:daniel)
    Locales::Assign.call(night: game_sessions(:david), locale: "pt-BR", player: player)

    assert_equal "pt-BR", player.reload.locale
  end

  test "refuses a player from another night" do
    assert_raises(People::Error) do
      Locales::Assign.call(night: game_sessions(:elias), locale: "fr", player: players(:lucia))
    end
  end
end
