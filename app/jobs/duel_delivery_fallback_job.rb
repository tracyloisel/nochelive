class DuelDeliveryFallbackJob < ApplicationJob
  queue_as :notifications_transactional

  def perform(invitation)
    invitation.reload
    return if invitation.delivered_at || invitation.seen_at || invitation.claimed_at
    return unless invitation.named? && invitation.available?

    Notifications::DuelInvitation.call(invitation:)
  end
end
