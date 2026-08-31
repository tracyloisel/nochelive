class QuizAdvancesController < ApplicationController
  include StreetQuiz
  before_action :load_quiz_run, :authorize_quiz_run

  def create
    street = Quizzes::Advance.call(run: @run)
    street ? replace_street(street.run) : redirect_to(night_path(@run.game_session.code))
  rescue RuntimeError, ActiveRecord::RecordInvalid
    redirect_to quiz_error_path
  end
end
