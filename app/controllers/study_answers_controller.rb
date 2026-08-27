class StudyAnswersController < ApplicationController
  include StudyIdentity

  def create
    load_study_run
    raise ActiveRecord::RecordInvalid, @run if @run.completed? || @run.settled?

    base = @run.study_quiz_version.question_at(@run.position)
    choice = params.require(:choice).to_s
    allowed = @run.question.fetch("choices").keys
    raise ActionController::BadRequest, "Unknown choice" unless allowed.include?(choice)

    correct = choice == base.fetch("correct_choice")
    answer = StudyRun.transaction do
      created = @run.study_answers.create!(question_key: base.fetch("key"), choice_key: choice, correct:)
      @run.increment!(:score) if correct
      created
    end
    redirect_to study_run_path(@run, reveal: answer.id)
  end
end
