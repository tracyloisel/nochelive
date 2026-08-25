class QuizExpiresController < ApplicationController
  include StreetQuiz
  before_action :load_street_run

  def create
    Quizzes::Expire.call(run: @run)
    replace_street(@run.reload)
  rescue RuntimeError, ActiveRecord::RecordInvalid
    redirect_to root_path
  end
end
