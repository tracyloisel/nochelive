require "test_helper"

class Nights::QuizSequenceTest < ActiveSupport::TestCase
  test "starts ordered normal quiz runs in the live context" do
    night = game_sessions(:david)
    night.update_columns(starts_at: 5.minutes.ago, ends_at: 55.minutes.from_now, status: "playing", quiz_pack_ids: %w[coronas moises])
    player = players(:lucia)
    digest = GameSession.digest_token("lucia-live")

    run = Nights::QuizSequence.current_or_start(night:, player:, device_digest: digest)
    assert_equal "coronas", run.pack_id
    assert_equal [ night.id, player.id, player.team.id, 1 ], [ run.game_session_id, run.player_id, run.team_id, run.live_sequence_position ]

    run.update!(status: "finished")
    following = Nights::QuizSequence.next_after(run:)
    assert_equal "moises", following.pack_id
    assert_equal 2, following.live_sequence_position
  end
end
