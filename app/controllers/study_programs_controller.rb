class StudyProgramsController < ApplicationController
  include StudyIdentity

  def show
    remember_device
    @program = current_study_program
    return render :empty unless @program

    @week = @program.current_week || @program.study_units.weeks.first
    @weeks = @program.study_units.weeks.includes(:study_quiz_versions)
    @appendices = @program.study_units.appendices
    @reflections = @program.study_units.where(kind: "reflection")
    identity_runs = study_runs_for_identity
      .joins(study_quiz_version: :study_unit).merge(@program.study_units)
    @completed_unit_ids = identity_runs.completed.reorder(nil).distinct.pluck("study_units.id").to_set
    week_runs = identity_runs.where(study_units: { id: @week&.id }).reorder(nil)
    @run = week_runs.completed.order(completed_at: :desc).first || week_runs.open.order(updated_at: :desc).first
    @quiz_reading_suggestions = Quizzes::ReadingSuggestions.call(person: current_street_person)
  end
end
