class StudyHistoriesController < ApplicationController
  include StudyIdentity

  SCRIPTURE_COLLECTIONS = {
    old_testament: "ot/",
    new_testament: "nt/",
    book_of_mormon: "bofm/",
    doctrine_and_covenants: "dc-testament/"
  }.freeze

  def show
    remember_device
    @program = StudyProgram.order(year: :desc).first
    @weeks = @program ? @program.study_units.weeks.includes(:study_quiz_versions) : StudyUnit.none
    @runs_by_unit_id = runs_by_unit_id
    @completed_count = @runs_by_unit_id.values.count(&:completed?)
    @chapters_by_collection = chapters_by_collection
    @highlighted_passages = highlighted_passages
    @current_week = @program&.current_week
  end

  private

    def runs_by_unit_id
      return {} unless @program

      study_runs_for_identity
        .joins(study_quiz_version: :study_unit)
        .where(study_units: { study_program_id: @program.id })
        .includes(:study_answers, study_quiz_version: :study_unit)
        .order(updated_at: :desc)
        .group_by { |run| run.study_quiz_version.study_unit_id }
        .transform_values { |unit_runs| unit_runs.find(&:completed?) || unit_runs.first }
    end

    def chapters_by_collection
      references = if current_street_person
        (
          current_street_person.scripture_chapter_reads.distinct.pluck(:reference) +
          current_street_person.scripture_highlights.distinct.pluck(:reference)
        ).uniq
      else
        []
      end

      SCRIPTURE_COLLECTIONS.transform_values do |prefix|
        references.count { |reference| reference.start_with?(prefix) }
      end
    end

    def highlighted_passages
      return [] unless current_street_person

      @highlight_chapters = {}
      highlights = current_street_person.scripture_highlights.order(updated_at: :desc, id: :desc).to_a
      reader_counts = ScriptureChapterRead.where(reference: highlights.map(&:reference))
        .group(:reference).distinct.count(:reader_digest)
      highlights.filter_map do |highlight|
        reference = Scriptures::Reference.from_study(
          study: highlight.reference, locale: highlight.locale, verse: highlight.start_verse
        )
        next unless reference

        verses = highlight.start_verse == highlight.end_verse ? highlight.start_verse.to_s : "#{highlight.start_verse}–#{highlight.end_verse}"
        {
          record: highlight,
          collection: SCRIPTURE_COLLECTIONS.find { |_collection, prefix| highlight.reference.start_with?(prefix) }&.first,
          citation: "#{reference.book_label} #{reference.chapter}:#{verses}",
          text: highlight.selected_text.presence || legacy_highlight_text(highlight),
          readers_count: reader_counts.fetch(highlight.reference, 0),
          path: scripture_passage_path(
            **Scriptures::Reference.passage_path_options(reference, highlight.locale, to: highlight.end_verse),
            start: highlight.start_offset, end: highlight.end_offset
          )
        }
      end
    end

    def legacy_highlight_text(highlight)
      chapter = @highlight_chapters.fetch([ highlight.reference, highlight.locale ]) do |key|
        @highlight_chapters[key] = Scriptures::Read.call(
          study: highlight.reference, locale: highlight.locale, public: true
        )
      end
      return unless chapter

      chapter.verses.filter_map do |verse|
        next unless verse.number.between?(highlight.start_verse, highlight.end_verse)

        from = verse.number == highlight.start_verse ? highlight.start_offset : 0
        to = verse.number == highlight.end_verse ? highlight.end_offset : verse.text.length
        verse.text[from...to]
      end.join(" ").squish.presence
    end
end
