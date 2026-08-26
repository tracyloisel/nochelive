module Quizzes
  class Leaderboard
    LIMIT_MINI = 5
    LIMIT_STRIP = 3
    LIMIT_PAGE = 25

    Row = Struct.new(:rank, :person, :score, :you, :context, keyword_init: true)
    Board = Struct.new(:rows, :your_rank, :your_score, :pack_id, :players, :page, :pages, keyword_init: true)

    def self.call(ward:, pack_id: nil, person: nil, limit: LIMIT_MINI, offset: 0, q: nil, include_you: false)
      new(ward:, pack_id:, person:, limit:, offset:, q:, include_you:).call
    end

    def initialize(ward:, pack_id: nil, person: nil, limit: LIMIT_MINI, offset: 0, q: nil, include_you: false)
      @ward = ward
      @pack_id = pack_id
      @person = person
      @limit = limit
      @offset = offset
      @q = q
      @include_you = include_you
    end

    def call
      scores = ranked_scores
      ordered = scores.sort_by { |_, score| -score }
      ordered = filter_by_query(ordered) if @q.present?
      players = ordered.size
      your_rank = rank_for(ordered, @person&.id)
      your_score = @person ? scores[@person.id].to_i : nil
      slice = @limit.positive? ? ordered[@offset, @limit] || [] : []
      you_in_slice = slice.any? { |person_id, _| person_id == @person&.id }
      context_slice = []
      if @include_you && @person && your_rank && !you_in_slice
        context_slice = [ [ @person.id, your_score ] ]
      end
      person_ids = (slice.map(&:first) + context_slice.map(&:first)).uniq
      people_by_id = load_people(person_ids)
      rows = build_rows(slice, people_by_id, offset: @offset)
      rows.concat(build_context_rows(context_slice, people_by_id, your_rank:))
      page = page_number
      pages = page_count(players)

      Board.new(
        rows:,
        your_rank:,
        your_score:,
        pack_id: @pack_id,
        players:,
        page:,
        pages:
      )
    end

    private

      def rank_for(ordered, person_id)
        return nil unless person_id

        ordered.index { |row_person_id, _| row_person_id == person_id }&.+(1)
      end

      def filter_by_query(ordered)
        matching_ids = search_person_ids(@q)
        ordered.select { |person_id, _| matching_ids.include?(person_id) }
      end

      def search_person_ids(query)
        key = Person.name_key(query)
        return [] if key.blank?

        @ward.people.where("given_name_key LIKE :key OR family_name_key LIKE :key", key: "#{key}%").pluck(:id)
      end

      def build_rows(slice, people_by_id, offset:)
        slice.each_with_index.filter_map do |(person_id, score), index|
          row_person = people_by_id[person_id]
          next unless row_person

          Row.new(
            rank: offset + index + 1,
            person: row_person,
            score:,
            you: @person&.id == person_id,
            context: false
          )
        end
      end

      def build_context_rows(context_slice, people_by_id, your_rank:)
        context_slice.filter_map do |(person_id, score)|
          row_person = people_by_id[person_id]
          next unless row_person

          Row.new(
            rank: your_rank,
            person: row_person,
            score:,
            you: true,
            context: true
          )
        end
      end

      def load_people(person_ids)
        return {} if person_ids.empty?

        @ward.people.where(id: person_ids).index_by(&:id)
      end

      def page_number
        return 1 unless @limit.positive?

        (@offset / @limit) + 1
      end

      def page_count(players)
        return 1 unless @limit.positive?

        [ (players.to_f / @limit).ceil, 1 ].max
      end

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
  end
end
