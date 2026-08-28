module Hubs
  class Invitations
    Item = Struct.new(:token, :state, :friend_name, :pack_title, :score, :sent_at, :url, keyword_init: true)
    Result = Struct.new(:items, :total, :waiting, :joined, keyword_init: true) do
      def any? = total.positive?
    end

    LIMIT = 3

    def self.call(person:, at: Time.current)
      new(person:, at:).call
    end

    def initialize(person:, at:)
      @person = person
      @at = at
      @helpers = Rails.application.routes.url_helpers
    end

    def call
      return Result.new(items: [], total: 0, waiting: 0, joined: 0) unless @person

      duels = shared_duels.to_a
      Result.new(
        items: duels.first(LIMIT).map { |duel| item_for(duel) },
        total: duels.size,
        waiting: duels.count { |duel| waiting?(duel) },
        joined: duels.count { |duel| duel.opponent_person_id.present? }
      )
    end

    private

      def shared_duels
        StreetDuel
          .joins(:viral_events)
          .where(challenger_person_id: @person.id, viral_events: { name: "invite_share_completed" })
          .where.not(status: "archived")
          .where("street_duels.expires_at > :at OR street_duels.status = :resolved", at: @at, resolved: "resolved")
          .includes(:opponent_person)
          .preload(:viral_events)
          .distinct
          .order(created_at: :desc)
      end

      def item_for(duel)
        Item.new(
          token: duel.token,
          state: state_for(duel),
          friend_name: duel.opponent_person&.given_name,
          pack_title: QuizDefinition.catalog.find_pack(duel.pack_id).copy(:title),
          score: duel.challenger_score.to_i,
          sent_at: duel.viral_events.select { |event| event.name == "invite_share_completed" }.min_by(&:created_at)&.created_at || duel.created_at,
          url: @helpers.street_challenge_path(duel.token, src: "reminder")
        )
      end

      def state_for(duel)
        return :completed if duel.resolved?
        return :playing if duel.opponent_person_id.present? || event?(duel, "challenge_started")
        return :opened if event?(duel, "invite_link_opened")

        :sent
      end

      def waiting?(duel)
        %i[sent opened].include?(state_for(duel))
      end

      def event?(duel, name)
        duel.viral_events.any? { |event| event.name == name }
      end
  end
end
