require "test_helper"

class Cheers::SendTest < ActiveSupport::TestCase
  setup do
    @night = game_sessions(:david)
    @round = round_runs(:finale_prophet)
    @round.update!(phase: "intro", layer_index: 1)
    @night.round_runs.where.not(id: @round.id).update_all(phase: "completed")
    @sender = players(:daniel)
    @lucia = players(:lucia)
  end

  test "records one cheer per player per layer" do
    one = Cheers::Send.call(night: @night, player: @sender, to_player: @lucia)
    two = Cheers::Send.call(night: @night, player: @sender, to_player: @lucia)
    assert_equal one.id, two.id
    assert_equal 1, Cheer.where(round_run: @round, player: @sender, layer_index: 1).count
    assert_equal "fire", one.mark
    assert_equal 1, @round.cheers.where(to_player: @lucia, layer_index: 1).count
  end

  test "refuses chapel spectator and salsa layer" do
    assert_raises(RuntimeError) do
      Cheers::Send.call(night: @night, player: @lucia, to_player: @sender)
    end
    assert_raises(RuntimeError) do
      Cheers::Send.call(night: @night, player: players(:publico), to_player: @lucia)
    end
    @round.update!(layer_index: 4)
    assert_raises(RuntimeError) do
      Cheers::Send.call(night: @night, player: @sender, to_player: @lucia)
    end
  end

  test "second tap does not pulse again" do
    pulses = capture_pulses(@night) do
      Cheers::Send.call(night: @night, player: @sender, to_player: @lucia)
      Cheers::Send.call(night: @night, player: @sender, to_player: @lucia)
    end
    kinds = pulses.map { |pulse| pulse&.fetch(:kind, nil) }
    assert_equal [ "cheer" ], kinds.compact
    assert_equal "¡Daniel anima a Lucía!", pulses.first[:label]
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
