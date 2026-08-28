require "test_helper"

class Audience::RespondTest < ActiveSupport::TestCase
  setup do
    @night = game_sessions(:david)
    @round = round_runs(:salomon)
    @now = Time.zone.parse("2026-08-28 20:00:10")
    @round.update!(phase: "open", opened_at: @now - 2.seconds)
  end

  test "records one immutable prediction without changing official scores" do
    score_count = @night.score_events.count
    response = Audience::Respond.call(
      night: @night,
      round: @round,
      audience_digest: "audience-a",
      choice: "wisdom",
      now: @now
    )
    duplicate = Audience::Respond.call(
      night: @night,
      round: @round,
      audience_digest: "audience-a",
      choice: "riches",
      now: @now + 1.second
    )

    assert_equal response.id, duplicate.id
    assert_equal "wisdom", duplicate.reload.choice
    assert_equal score_count, @night.score_events.count
  end

  test "rejects invalid and late predictions" do
    assert_raises(Audience::Respond::InvalidChoice) do
      Audience::Respond.call(night: @night, round: @round, audience_digest: "audience-a", choice: "spoiler", now: @now)
    end

    @round.update!(phase: "locked", locked_at: @now)
    assert_raises(Audience::Respond::Closed) do
      Audience::Respond.call(night: @night, round: @round, audience_digest: "audience-a", choice: "wisdom", now: @now)
    end
  end
end
