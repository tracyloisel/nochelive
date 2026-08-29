module Quizzes
  class DuelInvitationNotify
    def self.call(invitation:)
      return [] unless invitation.named? && invitation.available?

      recipient = invitation.recipient_person
      return Notifications::DuelInvitation.call(invitation:) unless Notifications::DuelResults.live?(recipient)

      broadcast = I18n.with_locale(Locale.i18n(recipient.locale)) do
        Turbo::StreamsChannel.broadcast_replace_to(
          [ recipient, :duel_campus ],
          target: "duel_campus_notice",
          partial: "street_challenges/ping",
          locals: { invitation:, viewer: recipient }
        )
      end
      DuelDeliveryFallbackJob.set(wait: 15.seconds).perform_later(invitation)
      Array(broadcast)
    end
  end
end
