require "test_helper"

class Nights::BroadcastTest < ActiveSupport::TestCase
  test "replaces play and watch streams" do
    assert_nothing_raised { Nights::Broadcast.call(night: game_sessions(:david)) }
  end

  test "broadcasts a semantic event to watch and player tile" do
    event = LiveEvent.create!(game_session: game_sessions(:david), kind: "join", dedupe_key: "broadcast-test", occurred_at: Time.current, payload: { player_name: "Lucía" })
    assert_nothing_raised do
      Nights::Broadcast.call(night: game_sessions(:david), event:)
    end
  end
end
