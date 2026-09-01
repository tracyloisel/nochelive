module Hubs
  # Selects the single real Campus action worthy of the Home. Waiting duels,
  # results and aggregate counts stay on the challenge page: none of them asks
  # the player to decide something now.
  class ChallengeCard
    Card = Struct.new(
      :kind, :state, :title, :pack_title, :path, :method, :due_at, :mine, :theirs,
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
          pack_title: pack_title_for(invitation),
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
          pack_title: pack_title_for(duel),
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

      def pack_title_for(item)
        pack_id = if item.respond_to?(:invitation)
          item.invitation&.challenger_run&.pack_id
        else
          [ item.theirs_run, item.mine_run, item.duel&.challenger_run, item.duel&.opponent_run,
            item.duel&.origin_invitation&.challenger_run ].compact.first&.pack_id
        end
        return unless pack_id

        exact_pack_title(pack_id)
      rescue QuizDefinition::Error
        nil
      end

      def exact_pack_title(pack_id)
        definition = QuizDefinition.catalog.find_pack(pack_id)
        presentation_key = "expedition_pack_presentations.#{pack_id}.title"
        quiz_key = "quizzes.#{pack_id}.title"
        key = [ presentation_key, quiz_key ].find do |candidate|
          I18n.exists?(candidate, I18n.locale, fallback: false)
        end
        return I18n.t(key, locale: I18n.locale, fallback: false).to_s.presence if key

        definition.title.to_s.presence if Locale.i18n(I18n.locale).to_s == "es"
      end
  end
end
