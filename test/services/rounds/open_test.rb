require "test_helper"

class Rounds::OpenTest < ActiveSupport::TestCase
  test "opens a pending round and pulses open" do
    round = round_runs(:rey_o_profeta)
    pulses = capture_pulses(round.game_session) do
      Rounds::Open.call(round:)
    end

    assert round.reload.open?
    assert round.opened_at.present?
    assert_equal [ "open" ], pulses.map { |pulse| pulse&.fetch(:kind, nil) }
  end

  test "is a no-op pulse when already open" do
    round = round_runs(:salomon)
    pulses = capture_pulses(round.game_session) do
      Rounds::Open.call(round:)
    end

    assert round.reload.open?
    assert_equal [ nil ], pulses
  end

  private

  def capture_pulses(_night)
    pulses = []
    original = GameSession.instance_method(:broadcast_state)
    GameSession.define_method(:broadcast_state) { |pulse: nil| pulses << pulse }
    yield
    pulses
  ensure
    GameSession.define_method(:broadcast_state, original)
  end
end
