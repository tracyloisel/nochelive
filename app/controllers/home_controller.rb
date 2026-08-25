class HomeController < ApplicationController
  include StreetQuiz

  def index
    @street = Quizzes::Draw.call(device_digest: street_digest)
  end
end
