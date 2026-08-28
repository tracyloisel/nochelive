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
        your_score: Leaderboard.total_score(person: @person)
      )
    end

    private

      def build_rivals
        people = stake_wards.flat_map(&:people).reject { |person| person.id == @person.id }
        live_ids = PersonDevice.where(person_id: people.map(&:id)).live.distinct.pluck(:person_id).to_set
        states = active_states(people.map(&:id))
        scores = pack_scores_by_ward
        ranks = stake_wards.to_h do |ward|
          ordered = scores.fetch(ward.id, {}).sort_by { |_, score| -score }.map(&:first)
          [ ward.id, ordered.each_with_index.to_h { |id, index| [ id, index + 1 ] } ]
        end
        wards_by_id = stake_wards.index_by(&:id)

        people.map do |person|
          Rival.new(
            person:,
            ward: wards_by_id.fetch(person.ward_id),
            score: scores.dig(person.ward_id, person.id).to_i,
            rank: ranks.dig(person.ward_id, person.id),
            live: live_ids.include?(person.id),
            state: states[person.id]
          )
        end.sort_by { |row| [ row.ward.id == @ward.id ? 0 : 1, row.live ? 0 : 1, -row.score, row.person.given_name_key ] }
      end

      def stake_wards
        @stake_wards ||= StakeScope.wards_for(ward: @ward).includes(:people).to_a
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

      def pack_scores_by_ward
        bests = QuizRun.adventure.finished
          .joins(:person)
          .where(people: { ward_id: stake_wards.map(&:id) }, pack_id: @pack_id)
          .group("people.ward_id", :person_id)
          .maximum(:score)
        bests.each_with_object(Hash.new { |hash, ward_id| hash[ward_id] = {} }) do |((ward_id, person_id), score), scores|
          scores[ward_id][person_id] = score.to_i
        end
      end

      def build_head_to_head
        recent = StreetDuel.where(status: "resolved")
          .where("challenger_person_id = :me OR opponent_person_id = :me", me: @person.id)
          .order(updated_at: :desc)
          .first
        other_id = if recent&.challenger_person_id == @person.id
          recent.opponent_person_id
        else
          recent&.challenger_person_id
        end
        other = Person.find_by(id: other_id)
        return unless other

        pair = StreetDuel.where(status: "resolved").where(
          "(challenger_person_id = :me AND opponent_person_id = :other) OR " \
          "(challenger_person_id = :other AND opponent_person_id = :me)",
          me: @person.id,
          other: other.id
        )
        you_wins, their_wins, ties = pair.pick(
          Arel.sql("COUNT(*) FILTER (WHERE (challenger_person_id = #{@person.id} AND challenger_score > opponent_score) OR (opponent_person_id = #{@person.id} AND opponent_score > challenger_score))"),
          Arel.sql("COUNT(*) FILTER (WHERE (challenger_person_id = #{other.id} AND challenger_score > opponent_score) OR (opponent_person_id = #{other.id} AND opponent_score > challenger_score))"),
          Arel.sql("COUNT(*) FILTER (WHERE challenger_score = opponent_score)")
        )
        HeadToHead.new(
          person: other,
          you_wins: you_wins.to_i,
          their_wins: their_wins.to_i,
          ties: ties.to_i
        )
      end
  end
end
