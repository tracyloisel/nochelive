module Quizzes
  class Rival
    Result = Struct.new(:person, :rank, :score, :gap, :pack_gap, keyword_init: true)

    def self.call(ward:, person: nil, pack_id: nil)
      return nil unless ward

      new(ward:, person:, pack_id:).call
    end

    def initialize(ward:, person: nil, pack_id: nil)
      @ward = ward
      @person = person
      @pack_id = pack_id
    end

    def call
      total_board = Leaderboard.call(ward: @ward, person: @person, limit: 0)
      rival_row = rival_row_for(total_board)
      pack_gap = pack_gap_for
      return nil unless rival_row

      gap = rival_row.score - (total_board.your_score || 0)
      Result.new(
        person: rival_row.person,
        rank: rival_row.rank,
        score: rival_row.score,
        gap:,
        pack_gap:
      )
    end

    private

      def rival_row_for(board)
        your_rank = board.your_rank
        if your_rank && your_rank > 1
          rival_board = Leaderboard.call(
            ward: @ward,
            pack_id: board.pack_id,
            person: @person,
            limit: 1,
            offset: your_rank - 2
          )
          return rival_board.rows.first
        end

        Leaderboard.call(
          ward: @ward,
          pack_id: board.pack_id,
          person: @person,
          limit: 2
        ).rows.find { |row| row.person&.id != @person&.id }
      end

      def pack_gap_for
        return nil unless @pack_id

        pack_board = Leaderboard.call(ward: @ward, pack_id: @pack_id, person: @person, limit: 0)
        pack_rival = rival_row_for(pack_board)
        return nil unless pack_rival

        pack_rival.score - (pack_board.your_score || 0)
      end
  end
end
