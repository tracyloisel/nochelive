require "test_helper"

class Quizzes::DuelInvitationCreateTest < ActiveSupport::TestCase
  test "creates an external invitation without choosing a pack" do
    result = Quizzes::DuelInvitationCreate.call(
      challenger_person: people(:pili),
      run: quiz_runs(:pili_coronas),
      source: "ceremony"
    )

    assert result.invitation.external?
    assert_equal 95, result.invitation.challenger_score
    assert_equal result.invitation, DuelInvitation.find_by_token(result.token)
    assert_not result.invitation.attributes.key?("pack_id")
  end

  test "a rematch creates an invitation and never forces the previous path" do
    previous = street_duels(:pili_vs_carmen)
    result = Quizzes::DuelInvitationCreate.call(
      challenger_person: people(:pili),
      recipient_person: people(:carmen_garcia),
      rematch_of_duel: previous,
      source: "duel_result"
    )

    assert result.invitation.rematch?
    assert_equal previous, result.invitation.rematch_of_duel
    assert_not result.invitation.attributes.key?("pack_id")
  end

  test "reuses an active pair instead of stacking another invitation" do
    invitation = duel_invitations(:named_pili_invitation)
    active = Quizzes::DuelInvitationClaim.call(
      invitation:,
      person: people(:carmen_garcia),
      device_digest: "carmen"
    ).duel

    assert_no_difference("DuelInvitation.count") do
      result = Quizzes::DuelInvitationCreate.call(
        challenger_person: people(:pili),
        recipient_person: people(:carmen_garcia)
      )
      assert_equal active, result.duel
    end
  end

  test "reuses the same open external handoff instead of stacking double taps" do
    first = Quizzes::DuelInvitationCreate.call(
      challenger_person: people(:pili),
      run: quiz_runs(:pili_coronas),
      source: "double-tap"
    )

    assert_no_difference("DuelInvitation.count") do
      second = Quizzes::DuelInvitationCreate.call(
        challenger_person: people(:pili),
        run: quiz_runs(:pili_coronas),
        source: "double-tap"
      )
      assert second.reused
      assert_equal first.invitation, second.invitation
      assert_equal first.token, second.token
    end
  end

  test "expires a stale pair before allowing a new invitation" do
    active = Quizzes::DuelInvitationClaim.call(
      invitation: duel_invitations(:named_pili_invitation),
      person: people(:carmen_garcia)
    ).duel
    active.update_column(:expires_at, 1.minute.ago)

    result = Quizzes::DuelInvitationCreate.call(
      challenger_person: people(:pili),
      recipient_person: people(:carmen_garcia)
    )

    assert active.reload.expired_status?
    assert result.invitation.open?
  end
end
