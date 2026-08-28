class StudyUnitsController < ApplicationController
  include StudyIdentity

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
      runs = study_runs_for_identity.joins(:study_quiz_version).where(study_quiz_versions: { study_unit_id: @unit.id })
      runs.completed.order(completed_at: :desc).first || runs.open.order(updated_at: :desc).first
    end
  end
end
