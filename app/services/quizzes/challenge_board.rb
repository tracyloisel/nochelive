module Quizzes
  class ChallengeBoard
    Rival = Struct.new(:person, :ward, :score, :rank, :live, :state, keyword_init: true)
    HeadToHead = Struct.new(:person, :you_wins, :their_wins, :ties, keyword_init: true)
    Result = Struct.new(:inbox, :rivalry, :rivals, :head_to_head, :pack_id, :your_score, keyword_init: true)

    def self.call(ward:, person:, pack_id:)
      new(ward:, person:, pack_id:).call
    end

    def initialize(ward:, person:, pack_id:)
      @ward = ward
      @person = person
      @pack_id = pack_id
    end

    def call
      Result.new(
        inbox: ChallengeInbox.call(person: @person),
        rivalry: StakeRivalry.call(ward: @ward),
        rivals: build_rivals,
        head_to_head: build_head_to_head,
        pack_id: @pack_id,
        your_score: Leaderboard.pack_best_totals(ward: @ward)[@person.id].to_i
      )
    end

    private

      def build_rivals
        wards = StakeScope.wards_for(ward: @ward).includes(:people)
        people = wards.flat_map(&:people).reject { |person| person.id == @person.id }
        live_ids = PersonDevice.where(person_id: people.map(&:id)).live.distinct.pluck(:person_id).to_set
        states = active_states(people.map(&:id))
        scores = wards.to_h { |ward| [ ward.id, pack_scores(ward) ] }
        ranks = wards.to_h do |ward|
          ordered = scores.fetch(ward.id).sort_by { |_, score| -score }.map(&:first)
          [ ward.id, ordered.each_with_index.to_h { |id, index| [ id, index + 1 ] } ]
        end

        people.map do |person|
          Rival.new(
            person:,
            ward: person.ward,
            score: scores.dig(person.ward_id, person.id).to_i,
            rank: ranks.dig(person.ward_id, person.id),
            live: live_ids.include?(person.id),
            state: states[person.id]
          )
        end.sort_by { |row| [ row.ward.id == @ward.id ? 0 : 1, row.live ? 0 : 1, -row.score, row.person.given_name_key ] }
      end

      def active_states(ids)
        return {} if ids.empty?

        StreetDuel.active.not_expired
          .where("challenger_person_id = :me OR opponent_person_id = :me", me: @person.id)
          .where("challenger_person_id IN (:ids) OR opponent_person_id IN (:ids)", ids:)
          .each_with_object({}) do |duel, memo|
            other_id = duel.challenger_person_id == @person.id ? duel.opponent_person_id : duel.challenger_person_id
            memo[other_id] = :waiting if other_id
          end
      end

      def pack_scores(ward)
        QuizRun.adventure.finished
          .joins(:person)
          .where(people: { ward_id: ward.id }, pack_id: @pack_id)
          .group(:person_id)
          .maximum(:score)
          .transform_values(&:to_i)
      end

      def build_head_to_head
        duels = StreetDuel.where(status: "resolved")
          .where("challenger_person_id = :me OR opponent_person_id = :me", me: @person.id)
          .includes(:challenger_person, :opponent_person)
          .order(updated_at: :desc)
        other = duels.first && other_person(duels.first)
        return unless other

        pair = duels.select { |duel| [ duel.challenger_person_id, duel.opponent_person_id ].include?(other.id) }
        HeadToHead.new(
          person: other,
          you_wins: pair.count { |duel| duel.winner_person&.id == @person.id },
          their_wins: pair.count { |duel| duel.winner_person&.id == other.id },
          ties: pair.count { |duel| duel.challenger_score == duel.opponent_score }
        )
      end

      def other_person(duel)
        duel.challenger_person_id == @person.id ? duel.opponent_person : duel.challenger_person
      end
  end
end
