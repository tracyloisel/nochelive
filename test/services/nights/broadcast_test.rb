require "test_helper"

class Nights::BroadcastTest < ActiveSupport::TestCase
  test "replaces play watch and presenter streams" do
    assert_nothing_raised { Nights::Broadcast.call(night: game_sessions(:david)) }
  end

  test "appends a pulse when a player buzzes" do
    assert_nothing_raised do
      Nights::Broadcast.call(night: game_sessions(:david), pulse: { kind: "buzz", player: players(:lucia) })
    end
  end
end
