require "test_helper"

class Quizzes::DuelInvitationClaimTest < ActiveSupport::TestCase
  test "claiming a named invitation activates a pair without starting a special quiz" do
    invitation = duel_invitations(:named_pili_invitation)

    result = Quizzes::DuelInvitationClaim.call(
      invitation:,
      person: people(:carmen_garcia),
      device_digest: "carmen-device"
    )

    assert result.created
    assert result.duel.active?
    assert_equal invitation.reload, result.duel.origin_invitation
    assert_equal result.duel, invitation.street_duel
    assert_nil result.duel.challenger_run
    assert_nil result.duel.opponent_run
  end

  test "the same person can safely claim the same invitation again" do
    invitation = duel_invitations(:named_pili_invitation)
    first = Quizzes::DuelInvitationClaim.call(invitation:, person: people(:carmen_garcia))
    second = Quizzes::DuelInvitationClaim.call(invitation: invitation.reload, person: people(:carmen_garcia))

    assert_equal first.duel, second.duel
    assert_not second.created
  end

  test "two invitations for the same pair converge on one active duel" do
    first_invitation = duel_invitations(:named_pili_invitation)
    second_invitation = DuelInvitation.create!(
      challenger_person: people(:pili),
      recipient_person: people(:carmen_garcia),
      token_digest: SecureRandom.hex(32),
      status: "open",
      expires_at: 7.days.from_now
    )

    first = Quizzes::DuelInvitationClaim.call(invitation: first_invitation, person: people(:carmen_garcia))
    second = Quizzes::DuelInvitationClaim.call(invitation: second_invitation, person: people(:carmen_garcia))

    assert first.created
    assert_not second.created
    assert_equal first.duel, second.duel
    assert_equal first.duel, second_invitation.reload.street_duel
    assert_equal 1, StreetDuel.active.where(pair_low_person_id: first.duel.pair_low_person_id, pair_high_person_id: first.duel.pair_high_person_id).count
  end

  test "claiming after pair expiry retires the stale row before creating the next duel" do
    first = Quizzes::DuelInvitationClaim.call(
      invitation: duel_invitations(:named_pili_invitation),
      person: people(:carmen_garcia)
    ).duel
    first.update_column(:expires_at, 1.minute.ago)
    second_invitation = DuelInvitation.create!(
      challenger_person: people(:pili),
      recipient_person: people(:carmen_garcia),
      token_digest: SecureRandom.hex(32),
      status: "open",
      expires_at: 7.days.from_now
    )

    result = Quizzes::DuelInvitationClaim.call(invitation: second_invitation, person: people(:carmen_garcia))

    assert first.reload.expired_status?
    assert result.created
    assert_not_equal first, result.duel
  end
end
