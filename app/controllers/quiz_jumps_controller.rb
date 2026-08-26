class QuizJumpsController < ApplicationController
  include StreetQuiz
  before_action :load_street_run

  def create
    street = Quizzes::Jump.call(run: @run, position: params[:position])
    replace_street(street.run)
  rescue RuntimeError, ActiveRecord::RecordInvalid
    redirect_to jugar_path
  end
end
