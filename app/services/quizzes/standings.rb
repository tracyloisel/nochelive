module Quizzes
  class Standings
    Result = Struct.new(
      :total_rank, :total_score, :total_players, :pack_rank, :pack_score,
      :rank_title, :total_board, :pack_board,
      keyword_init: true
    )

    def self.call(ward:, person:, pack_id: nil)
      return nil unless ward && person

      new(ward:, person:, pack_id:).call
    end

    def initialize(ward:, person:, pack_id: nil)
      @ward = ward
      @person = person
      @pack_id = pack_id
    end

    def call
      total_board = Leaderboard.call(
        ward: @ward,
        person: @person,
        limit: Leaderboard::LIMIT_MINI,
        include_you: true
      )
      pack_board = @pack_id ? Leaderboard.call(
        ward: @ward,
        pack_id: @pack_id,
        person: @person,
        limit: Leaderboard::LIMIT_MINI,
        include_you: true
      ) : nil

      Result.new(
        total_rank: total_board.your_rank,
        total_score: total_board.your_score.to_i,
        total_players: total_board.players,
        pack_rank: pack_board&.your_rank,
        pack_score: pack_board&.your_score.to_i,
        rank_title: rank_title(total_board.your_score.to_i),
        total_board:,
        pack_board:
      )
    end

    private

      def rank_title(score)
        Team::RANKS.reverse.find { |threshold, _, _| score >= threshold }&.third || Team::RANKS.first.last
      end
  end
end
