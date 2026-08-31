module Hubs
  # Selects the one or two concrete things that deserve attention after the
  # Hub hero. It is deliberately fed presentation data already loaded for the
  # screen: no additional queries, no invented recommendation, and no second
  # copy of the current adventure or Noche Live.
  class NowCards
    Card = Struct.new(
      :kind, :state, :title, :cite, :artwork, :path, :method,
      :progress_status, :progress_percent, :due_at, :mine, :theirs,
      keyword_init: true
    )

    ACTIONABLE_DUEL_STATES = %i[your_turn ready].freeze

    def self.call(campus:, reading_cards:, weekly_reading_cards:)
      new(
        campus:,
        reading_cards:,
        weekly_reading_cards:
      ).call
    end

    def initialize(campus:, reading_cards:, weekly_reading_cards:)
      @campus = campus
      @reading_cards = Array(reading_cards)
      @weekly_reading_cards = Array(weekly_reading_cards)
      @routes = Rails.application.routes.url_helpers
    end

    def call
      [ challenge_card, reading_card ].compact.first(2)
    end

    private

      # An invitation or a turn in progress has a real deadline and therefore
      # comes before a learning suggestion. Results and waiting duels stay in
      # Campus: they are useful history, not a "do this now" request.
      def challenge_card
        incoming_card || active_card
      end

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

      # Quiz-informed chapters have precedence over the weekly programme.
      # The latter remains a meaningful real next reading for a new player or
      # anyone without a quiz recommendation yet.
      def reading_card
        if (card = next_actionable_reading(@reading_cards))
          reading_card_for(card, kind: :quiz_reading)
        elsif (card = next_actionable_reading(@weekly_reading_cards))
          reading_card_for(card, kind: :weekly_reading)
        end
      end

      def next_actionable_reading(cards)
        cards.find { |card| card.status != :completed }
      end

      def reading_card_for(card, kind:)
        path_options = { cite: card.cite }
        path_options[:study_unit_id] = card.study_unit_id if card.respond_to?(:study_unit_id) && card.study_unit_id.present?

        Card.new(
          kind:,
          state: card.status,
          title: card.title,
          cite: card.cite,
          artwork: card.artwork,
          path: @routes.scripture_path(card.study, **path_options),
          method: :get,
          progress_status: card.status,
          progress_percent: card.progress_percent
        )
      end
  end
end
