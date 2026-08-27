class StudyUnitsController < ApplicationController
  def show
    remember_device
    @unit = StudyUnit.find(params[:id])
    @quiz = @unit.published_quiz
    @opened_reading_references = if current_street_person
      @unit.reading_progresses.where(person: current_street_person).pluck(:reference).to_set
    else
      Set.new
    end
    @run = if @quiz
      runs = StudyRun.joins(:study_quiz_version).where(
        study_quiz_versions: { study_unit_id: @unit.id },
        device_digest: street_device_digest,
        person_id: current_street_person&.id
      )
      runs.completed.order(completed_at: :desc).first || runs.open.order(updated_at: :desc).first
    end
  end
end
