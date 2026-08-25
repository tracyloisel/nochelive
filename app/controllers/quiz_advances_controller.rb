class QuizAdvancesController < ApplicationController
  include StreetQuiz
  before_action :load_street_run

  def create
    street = Quizzes::Advance.call(run: @run)
    replace_street(street.run)
  rescue RuntimeError, ActiveRecord::RecordInvalid
    redirect_to root_path
  end
end
