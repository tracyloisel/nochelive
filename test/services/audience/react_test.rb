require "test_helper"

class Audience::ReactTest < ActiveSupport::TestCase
  setup do
    @night = game_sessions(:david)
    @round = round_runs(:salomon)
    @now = Time.zone.parse("2026-08-28 20:00:10")
    @round.update!(phase: "open", opened_at: @now - 1.second)
  end

  test "rate limits reactions per audience member" do
    @night.define_singleton_method(:broadcast_state) { |pulse: nil| pulse }
    Audience::React.call(night: @night, round: @round, audience_digest: "audience-a", mark: "heart", now: @now)
    assert_raises(Audience::React::RateLimited) do
      Audience::React.call(night: @night, round: @round, audience_digest: "audience-a", mark: "crown", now: @now + 1.second)
    end
    assert_nothing_raised do
      Audience::React.call(night: @night, round: @round, audience_digest: "audience-a", mark: "crown", now: @now + 3.seconds)
    end
  end

  test "rejects unknown reaction marks" do
    assert_raises(ActiveRecord::RecordInvalid) do
      Audience::React.call(night: @night, round: @round, audience_digest: "audience-a", mark: "fireworks", now: @now)
    end
  end
end
