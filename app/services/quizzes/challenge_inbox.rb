module Quizzes
  class ChallengeInbox
    RECENT = 14.days
    Item = Struct.new(:duel, :role, :phase, :other, :pack, :waiting_for, keyword_init: true)
    Result = Struct.new(:incoming, :waiting, :recent, keyword_init: true)

    def self.call(person:)
      new(person:).call
    end

    def self.actionable_count(person:)
      return 0 unless person

      StreetDuel.active.not_expired.where(opponent_person_id: person.id).count
    end

    def initialize(person:)
      @person = person
    end

    def call
      Result.new(
        incoming: items_for(incoming_scope, :opponent),
        waiting: items_for(waiting_scope, :challenger),
        recent: items_for(recent_scope)
      )
    end

    private

      def incoming_scope
        StreetDuel.active.not_expired
          .includes(:challenger_person, :opponent_run)
          .where(opponent_person_id: @person.id)
          .order(updated_at: :desc, id: :desc)
      end

      def waiting_scope
        StreetDuel.active.not_expired
          .includes(:opponent_person, :opponent_run)
          .where(challenger_person_id: @person.id)
          .order(updated_at: :desc, id: :desc)
      end

      def recent_scope
        StreetDuel.where(status: "resolved")
          .includes(:challenger_person, :opponent_person)
          .where("challenger_person_id = :id OR opponent_person_id = :id", id: @person.id)
          .where("updated_at > ?", RECENT.ago)
          .order(updated_at: :desc, id: :desc)
          .limit(8)
      end

      def items_for(scope, role = nil)
        scope.filter_map do |duel|
          pack = QuizDefinition.catalog.find_pack(duel.pack_id)
          next unless pack

          screen = ChallengeScreen.call(duel:, person: @person)
          next unless screen
          next if role && screen.role != role

          Item.new(
            duel:,
            role: screen.role,
            phase: screen.phase,
            other: other_person(duel),
            pack:,
            waiting_for: screen.waiting_for
          )
        end
      end

      def other_person(duel)
        duel.challenger_person_id == @person.id ? duel.opponent_person : duel.challenger_person
      end
  end
end
