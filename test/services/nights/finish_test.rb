require "test_helper"

class Nights::FinishTest < ActiveSupport::TestCase
  test "finishes a playing night" do
    night = game_sessions(:david)
    night.update!(status: "playing")
    Nights::Finish.call(night:)
    assert night.reload.finished?
    assert night.season_applied_at.present?
  end
end
