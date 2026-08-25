class HomeController < ApplicationController
  include StreetQuiz

  def index
    @street = street_draw
    @street_trail = Quizzes::Trail.call(run: @street.run)
  end
end
