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
          current_street_person.scripture_marks.active.distinct.pluck(:reference)
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

      marks = current_street_person.scripture_marks.active.where(anchor_scope: "passage")
        .order(updated_at: :desc, id: :desc).to_a
      reader_counts = ScriptureChapterRead.where(reference: marks.map(&:reference))
        .group(:reference).distinct.count(:reader_digest)
      marks.filter_map do |mark|
        reference = Scriptures::Reference.from_study(
          study: mark.reference, locale: mark.locale, verse: mark.start_verse
        )
        next unless reference

        verses = mark.start_verse == mark.end_verse ? mark.start_verse.to_s : "#{mark.start_verse}–#{mark.end_verse}"
        {
          record: mark,
          collection: SCRIPTURE_COLLECTIONS.find { |_collection, prefix| mark.reference.start_with?(prefix) }&.first,
          citation: "#{reference.book_label} #{reference.chapter}:#{verses}",
          text: mark.selected_text,
          readers_count: reader_counts.fetch(mark.reference, 0),
          path: scripture_passage_path(
            **Scriptures::Reference.passage_path_options(reference, mark.locale, to: mark.end_verse),
            start: mark.start_offset, end: mark.end_offset
          )
        }
      end
    end
end
