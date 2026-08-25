module Quizzes
  class Leaderboard
    Row = Struct.new(:rank, :person, :score, :you, keyword_init: true)
    Board = Struct.new(:rows, :your_rank, :your_score, :pack_id, :players, keyword_init: true)

    def self.call(ward:, pack_id: nil, person: nil, limit: 5)
      new(ward:, pack_id:, person:, limit:).call
    end

    def initialize(ward:, pack_id: nil, person: nil, limit: 5)
      @ward = ward
      @pack_id = pack_id
      @person = person
      @limit = limit
    end

    def call
      scores = ranked_scores
      ordered = scores.sort_by { |_, score| -score }
      rows = ordered.first(@limit).each_with_index.map do |(person_id, score), index|
        row_person = people[person_id]
        next unless row_person

        Row.new(rank: index + 1, person: row_person, score:, you: @person&.id == person_id)
      end.compact
      your_rank = @person ? ordered.index { |person_id, _| person_id == @person.id }&.+(1) : nil
      Board.new(
        rows:,
        your_rank:,
        your_score: @person ? scores[@person.id].to_i : nil,
        pack_id: @pack_id,
        players: ordered.size
      )
    end

    private

      def ranked_scores
        if @pack_id
          pack_scores
        else
          total_scores
        end
      end

      def pack_scores
        QuizRun.finished
          .joins(:person)
          .where(people: { ward_id: @ward.id }, pack_id: @pack_id)
          .group(:person_id)
          .maximum(:score)
          .transform_values(&:to_i)
      end

      def total_scores
        bests = QuizRun.finished
          .joins(:person)
          .where(people: { ward_id: @ward.id })
          .group(:person_id, :pack_id)
          .maximum(:score)
        totals = Hash.new(0)
        bests.each { |(person_id, _), score| totals[person_id] += score.to_i }
        totals
      end

      def people
        @people ||= @ward.people.index_by(&:id)
      end
  end
end
