class QuizExpiresController < ApplicationController
  include StreetQuiz
  before_action :load_quiz_run, :authorize_quiz_run

  def create
    Quizzes::Expire.call(run: @run)
    replace_street(@run.reload)
  rescue RuntimeError, ActiveRecord::RecordInvalid
    redirect_to quiz_error_path
  end
end
