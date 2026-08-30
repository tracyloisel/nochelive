module Scriptures
  class ChapterHistory
    Result = Data.define(
      :first_read_at, :last_read_at, :qualified_days, :last_verse, :completed_at,
      :marks_count, :tags, :notebooks, :outgoing_links_count, :incoming_links_count
    )

    def self.call(person:, reference:, locale:, marks: nil, progress: nil)
      new(person:, reference:, locale:, marks:, progress:).call
    end

    def initialize(person:, reference:, locale:, marks:, progress:)
      @person = person
      @reference = reference
      @locale = Locale.cast(locale)
      @marks = marks
      @progress = progress
    end

    def call
      return empty_result unless @person

      marks = @marks || @person.scripture_marks
        .includes(:scripture_tags, :scripture_notebooks, :scripture_mark_links)
        .for_reader(reference: @reference, locale: @locale).to_a
      progress = @progress || @person.scripture_reading_progresses.find_by(reference: @reference, locale: @locale)
      reads = @person.scripture_chapter_reads.where(reference: @reference, locale: @locale)

      Result.new(
        first_read_at: reads.minimum(:created_at) || progress&.first_opened_at,
        last_read_at: reads.maximum(:created_at) || progress&.last_opened_at,
        qualified_days: reads.distinct.count(:read_on),
        last_verse: progress&.last_verse,
        completed_at: progress&.completed_at,
        marks_count: marks.size,
        tags: marks.flat_map(&:scripture_tags).uniq(&:id).map(&:name).sort,
        notebooks: marks.flat_map(&:scripture_notebooks).uniq(&:id).map(&:title).sort,
        outgoing_links_count: marks.sum { |mark| mark.scripture_mark_links.size },
        incoming_links_count: ScriptureMarkLink.joins(:scripture_mark).where(
          scripture_marks: { person_id: @person.id }, target_reference: @reference, target_locale: @locale
        ).count
      )
    end

    private

      def empty_result
        Result.new(
          first_read_at: nil, last_read_at: nil, qualified_days: 0, last_verse: nil,
          completed_at: nil, marks_count: 0, tags: [], notebooks: [],
          outgoing_links_count: 0, incoming_links_count: 0
        )
      end
  end
end
