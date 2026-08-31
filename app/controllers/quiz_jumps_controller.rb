class QuizJumpsController < ApplicationController
  include StreetQuiz
  before_action :load_quiz_run, :authorize_quiz_run

  def create
    street = Quizzes::Jump.call(run: @run, position: params[:position])
    replace_street(street.run)
  rescue RuntimeError, ActiveRecord::RecordInvalid
    redirect_to quiz_error_path
  end
end
