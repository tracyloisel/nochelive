module Quizzes
  class StakeRivalry
    WardScore = Struct.new(:ward, :score, :duels, :wins, keyword_init: true)
    Result = Struct.new(:home, :away, :lead, :leader, :total_duels, :contributors, :home_win_rate, keyword_init: true)

    def self.call(ward:)
      new(ward:).call
    end

    def initialize(ward:)
      @ward = ward
    end

    def call
      away = StakeScope.wards_for(ward: @ward).where.not(id: @ward.id).first
      return Result.new(home: ward_score(@ward), away: nil, lead: 0, leader: nil, total_duels: 0, contributors: 0, home_win_rate: 0) unless away

      pair = duels_between(@ward, away).to_a
      home = ward_score(@ward, against: away)
      rival = ward_score(away, against: @ward)
      leader = home.score == rival.score ? nil : (home.score > rival.score ? home : rival)
      Result.new(
        home:,
        away: rival,
        lead: (home.score - rival.score).abs,
        leader:,
        total_duels: pair.size,
        contributors: pair.flat_map { |duel| [ duel.challenger_person_id, duel.opponent_person_id ] }.compact.uniq.size,
        home_win_rate: pair.empty? ? 0 : ((home.wins.to_f / pair.size) * 100).round
      )
    end

    private

      def ward_score(ward, against: nil)
        scores = Leaderboard.pack_best_totals(ward:)
        duels = against ? duels_between(ward, against) : StreetDuel.none
        WardScore.new(
          ward:,
          score: scores.values.sum,
          duels: duels.count,
          wins: duels.count { |duel| winner_ward_id(duel) == ward.id }
        )
      end

      def duels_between(a, b)
        StreetDuel.where(status: "resolved").where(
          "(challenger_ward_id = :a AND opponent_ward_id = :b) OR (challenger_ward_id = :b AND opponent_ward_id = :a)",
          a: a.id, b: b.id
        )
      end

      def winner_ward_id(duel)
        return if duel.challenger_score == duel.opponent_score

        duel.challenger_score > duel.opponent_score ? (duel.challenger_ward_id || duel.ward_id) : duel.opponent_ward_id
      end
  end
end
