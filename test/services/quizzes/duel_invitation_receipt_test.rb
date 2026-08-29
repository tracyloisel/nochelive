require "test_helper"

class Quizzes::DuelInvitationReceiptTest < ActiveSupport::TestCase
  test "records distinct delivery and visible-read receipts for a named friend" do
    invitation = duel_invitations(:named_pili_invitation)
    recipient = people(:carmen_garcia)

    assert Quizzes::DuelInvitationReceipt.call(invitation:, state: :delivered, person: recipient)
    assert_equal :delivered, invitation.reload.receipt_state
    assert Quizzes::DuelInvitationReceipt.call(invitation:, state: :seen, person: recipient)
    assert_equal :seen, invitation.reload.receipt_state
  end

  test "a shared link counts as opened only after the visible-page receipt" do
    invitation = duel_invitations(:open_pili_invitation)

    assert_equal :sent, invitation.receipt_state
    assert Quizzes::DuelInvitationReceipt.call(invitation:, state: :human_opened, device_digest: "friend")
    assert_equal :opened, invitation.reload.receipt_state
  end

  test "declining records a visible decision without pretending it was accepted" do
    invitation = duel_invitations(:named_pili_invitation)

    Quizzes::DuelInvitationDecline.call(invitation:, person: people(:carmen_garcia))

    assert_equal :declined, invitation.reload.receipt_state
    assert invitation.seen_at
    assert_nil invitation.claimed_at
  end
end
