module Quizzes
  class Leaderboard
    LIMIT_MINI = 5
    LIMIT_STRIP = 3
    LIMIT_PAGE = 100

    Row = Struct.new(:rank, :person, :score, :answered, :you, :context, :live, :open_run, keyword_init: true)
    Board = Struct.new(
      :rows, :podium, :around, :rival, :your_row,
      :your_rank, :your_score, :your_answered, :your_live, :your_page,
      :pack_id, :players, :matching_players, :page, :pages,
      :next_offset, :previous_offset,
      keyword_init: true
    )

    def self.call(ward:, wards: nil, pack_id: nil, person: nil, limit: LIMIT_MINI, offset: 0, q: nil, include_you: false,
      include_ward: false)
      new(ward:, wards:, pack_id:, person:, limit:, offset:, q:, include_you:, include_ward:).call
    end

    def self.pack_best_totals(ward: nil, wards: nil)
      scope = QuizRun.finished
      if wards || ward
        ward_ids = wards ? wards.select(:id) : ward.id
        scope = scope.joins(:person).where(people: { ward_id: ward_ids })
      else
        scope = scope.where.not(person_id: nil)
      end
      bests = scope.group(:person_id, :pack_id).maximum(:score)
      totals = Hash.new(0)
      bests.each { |(person_id, _), score| totals[person_id] += score.to_i }
      totals
    end

    def self.total_scores(person_ids:)
      ids = Array(person_ids).compact.uniq
      return {} if ids.empty?

      bests = QuizRun.finished
        .where(person_id: ids)
        .group(:person_id, :pack_id)
        .maximum(:score)
      bests.each_with_object(Hash.new(0)) do |((person_id, _pack_id), score), totals|
        totals[person_id] += score.to_i
      end
    end

    def self.total_score(person:)
      return 0 unless person

      total_scores(person_ids: [ person.id ])[person.id]
    end

    def initialize(ward:, wards: nil, pack_id: nil, person: nil, limit: LIMIT_MINI, offset: 0, q: nil, include_you: false,
      include_ward: false)
      @ward = ward
      @wards = wards
      @pack_id = pack_id
      @person = person
      @limit = limit
      @offset = offset
      @q = q
      @include_you = include_you
      @include_ward = include_ward
    end

    def call
      scores = ranked_scores
      ordered = scores.sort_by { |person_id, score| [ -score.to_i, person_id.to_i ] }
      ranked = ordered.each_with_index.map { |(person_id, score), index| [ person_id, score, index + 1 ] }
      visible = filter_by_query(ranked) if @q.present?
      visible ||= ranked
      players = ranked.size
      matching_players = visible.size
      @offset = normalized_offset(matching_players)
      your_entry = ranked.find { |person_id, _score, _rank| person_id == @person&.id }
      your_rank = your_entry&.third
      your_score = @person ? scores[@person.id].to_i : nil
      slice = @limit.positive? ? visible[@offset, @limit] || [] : []
      you_in_slice = slice.any? { |person_id, _score, _rank| person_id == @person&.id }
      context_slice = []
      if @include_you && @person && your_rank && !you_in_slice
        context_slice = [ your_entry ]
      end
      podium_slice = ranked.first(3)
      around_slice = around_entries(ranked, your_rank)
      rival_entry = your_rank.to_i > 1 ? ranked[your_rank - 2] : nil
      person_ids = [ slice, context_slice, podium_slice, around_slice, [ your_entry, rival_entry ].compact ]
        .flatten(1)
        .map(&:first)
        .uniq
      people_by_id = load_people(person_ids)
      count_ids = @person ? (person_ids + [ @person.id ]).uniq : person_ids
      answered_by_id = answer_counts(count_ids)
      live_ids = live_person_ids(count_ids)
      open_runs_by_id = latest_open_runs(count_ids)
      rows = build_rows(slice, people_by_id, answered_by_id, live_ids, open_runs_by_id)
      rows.concat(build_rows(context_slice, people_by_id, answered_by_id, live_ids, open_runs_by_id, context: true))
      podium = build_rows(podium_slice, people_by_id, answered_by_id, live_ids, open_runs_by_id)
      around = build_rows(around_slice, people_by_id, answered_by_id, live_ids, open_runs_by_id)
      rival = build_rows([ rival_entry ].compact, people_by_id, answered_by_id, live_ids, open_runs_by_id).first
      your_row = build_rows([ your_entry ].compact, people_by_id, answered_by_id, live_ids, open_runs_by_id).first
      page = page_number
      pages = page_count(matching_players)
      your_page = page_for_rank(your_rank)
      your_answered = @person ? answered_by_id[@person.id].to_i : nil
      your_live = @person ? live_ids.include?(@person.id) : false
      next_offset = @offset + slice.size if @limit.positive? && (@offset + slice.size) < matching_players
      previous_offset = [ @offset - @limit, 0 ].max if @limit.positive? && @offset.positive?

      Board.new(
        rows:,
        podium:,
        around:,
        rival:,
        your_row:,
        your_rank:,
        your_score:,
        your_answered:,
        your_live:,
        your_page:,
        pack_id: @pack_id,
        players:,
        matching_players:,
        page:,
        pages:,
        next_offset:,
        previous_offset:
      )
    end

    private

      def filter_by_query(ordered)
        matching_ids = search_person_ids(@q).to_set
        ordered.select { |person_id, _score, _rank| matching_ids.include?(person_id) }
      end

      def search_person_ids(query)
        key = Person.name_key(query)
        return [] if key.blank?

        prefix = ActiveRecord::Base.sanitize_sql_like(key)
        people_scope.where("given_name_key LIKE :key OR family_name_key LIKE :key", key: "#{prefix}%").pluck(:id)
      end

      def build_rows(slice, people_by_id, answered_by_id, live_ids, open_runs_by_id, context: false)
        slice.filter_map do |person_id, score, rank|
          row_person = people_by_id[person_id]
          next unless row_person

          Row.new(
            rank:,
            person: row_person,
            score:,
            answered: answered_by_id[person_id].to_i,
            you: @person&.id == person_id,
            context:,
            live: live_ids.include?(person_id),
            open_run: open_runs_by_id[person_id]
          )
        end
      end

      def latest_open_runs(person_ids)
        return {} if person_ids.empty?

        QuizRun.open_runs.where(person_id: person_ids).order(id: :desc).each_with_object({}) do |run, rows|
          rows[run.person_id] ||= run
        end
      end

      def around_entries(ranked, your_rank)
        return [] unless your_rank

        start = [ your_rank - 2, 0 ].max
        start = [ start, ranked.size - LIMIT_STRIP ].min if ranked.size >= LIMIT_STRIP
        ranked.slice(start, LIMIT_STRIP) || []
      end

      def live_person_ids(person_ids)
        return Set.new if person_ids.empty?

        Presences::Registry.online_person_ids(among: person_ids)
      end

      def answer_counts(person_ids)
        return {} if person_ids.empty?

        QuizAnswer.joins(:quiz_run)
          .where(quiz_runs: { person_id: person_ids })
          .group("quiz_runs.person_id")
          .count
      end

      def load_people(person_ids)
        return {} if person_ids.empty?

        scope = people_scope.where(id: person_ids)
        scope = scope.includes(:ward) if @include_ward
        scope.index_by(&:id)
      end

      def page_number
        return 1 unless @limit.positive?

        (@offset / @limit) + 1
      end

      def normalized_offset(players)
        return 0 unless @limit.positive? && players.positive?

        [ @offset, ((players - 1) / @limit) * @limit ].min
      end

      def page_for_rank(rank)
        return nil unless rank && @limit.positive?

        ((rank - 1) / @limit) + 1
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
          .where(people: { ward_id: ward_ids }, pack_id: @pack_id)
          .group(:person_id)
          .maximum(:score)
          .transform_values(&:to_i)
      end

      def total_scores
        self.class.pack_best_totals(ward: @ward, wards: @wards)
      end

      def people_scope
        Person.where(ward_id: ward_ids)
      end

      def ward_ids
        @wards ? @wards.select(:id) : @ward.id
      end
  end
end
