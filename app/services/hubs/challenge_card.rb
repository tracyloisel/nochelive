module Hubs
  # Selects the single real Campus action worthy of the Home. Waiting duels,
  # results and aggregate counts stay on the challenge page: none of them asks
  # the player to decide something now.
  class ChallengeCard
    Card = Struct.new(
      :kind, :state, :title, :path, :method, :due_at, :mine, :theirs,
      keyword_init: true
    )

    ACTIONABLE_DUEL_STATES = %i[your_turn ready].freeze

    def self.call(campus:)
      new(campus:).call
    end

    def initialize(campus:)
      @campus = campus
      @routes = Rails.application.routes.url_helpers
    end

    def call
      incoming_card || active_card
    end

    private

      def incoming_card
        invitation = Array(@campus&.incoming)
          .sort_by { |item| [ item.invitation.expires_at, item.invitation.id ] }
          .find { |item| person_name_for(item).present? }
        return unless invitation

        Card.new(
          kind: :challenge,
          state: :incoming,
          title: person_name_for(invitation),
          path: @routes.street_challenge_accept_path(invitation.token),
          method: :post,
          due_at: invitation.invitation.expires_at
        )
      end

      def active_card
        duel = Array(@campus&.active)
          .select { |item| ACTIONABLE_DUEL_STATES.include?(item.state) }
          .sort_by { |item| [ duel_state_rank(item.state), -item.duel.updated_at.to_i, -item.duel.id ] }
          .find { |item| person_name_for(item).present? }
        return unless duel

        Card.new(
          kind: :challenge,
          state: duel.state,
          title: person_name_for(duel),
          path: @routes.street_duel_path(duel.duel),
          method: :get,
          mine: duel.mine,
          theirs: duel.theirs
        )
      end

      def duel_state_rank(state)
        state == :your_turn ? 0 : 1
      end

      def person_name_for(item)
        item.other&.display_name.to_s.presence
      end
  end
end
