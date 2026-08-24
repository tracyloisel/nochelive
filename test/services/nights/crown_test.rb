require "test_helper"

class Nights::CrownTest < ActiveSupport::TestCase
  test "reveals the finale and finishes the night" do
    night = game_sessions(:david)
    night.update!(status: "playing")
    round = round_runs(:finale_prophet)
    night.round_runs.where.not(id: round.id).update_all(phase: "completed")
    round.update!(phase: "open", opened_at: Time.current)

    Nights::Crown.call(night:, round:)

    assert night.reload.finished?
    assert_includes %w[revealed completed], round.reload.phase
  end

  test "rejects a non-finale round" do
    assert_raises(RuntimeError) do
      Nights::Crown.call(night: game_sessions(:david), round: round_runs(:salomon))
    end
  end
end
