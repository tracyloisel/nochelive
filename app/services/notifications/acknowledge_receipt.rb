module Notifications
  class AcknowledgeReceipt
    PURPOSE = :notification_receipt

    def self.call(delivery:)
      return false unless delivery

      changed = false
      delivery.with_lock do
        unless delivery.received_at
          delivery.update!(received_at: Time.current)
          changed = true
        end
      end
      return true unless changed

      if delivery.kind.in?(%w[duel_invitation duel_reminder]) && delivery.subject_type == "DuelInvitation"
        Quizzes::DuelInvitationReceipt.call(
          invitation: delivery.subject,
          person: delivery.person,
          state: :delivered
        )
      end
      true
    end
  end
end
