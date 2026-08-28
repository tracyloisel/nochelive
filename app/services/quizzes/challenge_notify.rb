module Quizzes
  class ChallengeNotify
    def self.call(duel:)
      new(duel:).call
    end

    def initialize(duel:)
      @duel = duel
    end

    def call
      opponent = @duel.opponent_person
      return unless opponent
      unless live?(opponent)
        Notifications::DuelInvitation.call(duel: @duel)
        return
      end

      I18n.with_locale(Locale.i18n(opponent.locale)) do
        Turbo::StreamsChannel.broadcast_replace_to(
          [ opponent, :street_duel ],
          target: "street_duel_ping",
          partial: "street_challenges/ping",
          locals: { duel: @duel, viewer: opponent }
        )
      end
    end

    private

      def live?(person)
        PersonDevice.where(person_id: person.id).live.exists? ||
          Player.where(person_id: person.id).live.exists?
      end
  end
end
