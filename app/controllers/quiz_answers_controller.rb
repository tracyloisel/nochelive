class QuizAnswersController < ApplicationController
  include StreetQuiz
  before_action :load_street_run

  def create
    Quizzes::Submit.call(run: @run, choice_key: params[:choice].to_s)
    replace_street(@run.reload)
  rescue RuntimeError, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    redirect_to root_path
  end
end
