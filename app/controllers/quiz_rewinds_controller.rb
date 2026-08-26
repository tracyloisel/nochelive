class QuizRewindsController < ApplicationController
  include StreetQuiz
  before_action :load_street_run

  def create
    street = Quizzes::Rewind.call(run: @run)
    replace_street(street.run)
  rescue RuntimeError, ActiveRecord::RecordInvalid
    redirect_to jugar_path
  end
end
