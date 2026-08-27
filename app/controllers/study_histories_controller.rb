class StudyHistoriesController < ApplicationController
  SCRIPTURE_COLLECTIONS = {
    old_testament: "ot/",
    new_testament: "nt/",
    book_of_mormon: "bofm/",
    doctrine_and_covenants: "dc-testament/"
  }.freeze
  PROGRAM_CANONS = {
    "old_testament" => :old_testament,
    "new_testament" => :new_testament,
    "book_of_mormon" => :book_of_mormon,
    "bom" => :book_of_mormon,
    "doctrine_and_covenants" => :doctrine_and_covenants,
    "dc" => :doctrine_and_covenants
  }.freeze

  def show
    remember_device
    @program = StudyProgram.order(year: :desc).first
    @weeks = @program ? @program.study_units.weeks.includes(:study_quiz_versions) : StudyUnit.none
    runs = StudyRun.where(
      device_digest: street_device_digest, person_id: current_street_person&.id
    ).includes(study_quiz_version: { study_unit: :study_program }).order(updated_at: :desc)
    @runs_by_unit_id = runs.group_by { |run| run.study_quiz_version.study_unit_id }.transform_values do |unit_runs|
      unit_runs.find(&:completed?) || unit_runs.first
    end
    @completed_count = @runs_by_unit_id.values.count(&:completed?)
    completed_chapters = @runs_by_unit_id.values.select(&:completed?).flat_map do |run|
      studied_chapters(run)
    end.uniq
    @chapters_by_collection = SCRIPTURE_COLLECTIONS.keys.index_with do |collection|
      completed_chapters.count { |chapter_collection, _chapter| chapter_collection == collection }
    end
    @current_week = @program&.current_week
  end

  private

    def studied_chapters(run)
      readings = run.study_quiz_version.readings
      if readings.any?
        readings.filter_map do |reading|
          study = reading.fetch("study")
          collection = SCRIPTURE_COLLECTIONS.find { |_key, prefix| study.start_with?(prefix) }&.first
          [ collection, study ] if collection
        end
      else
        collection = PROGRAM_CANONS[run.study_unit.study_program.canon]
        return [] unless collection

        run.study_quiz_version.questions.filter_map do |question|
          reference = question["scripture_ref"].to_s.sub(/:.*/, "").strip
          [ collection, reference ] if reference.present?
        end
      end
    end
end
