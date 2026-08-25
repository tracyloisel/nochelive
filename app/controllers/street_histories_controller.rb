class StreetHistoriesController < ApplicationController
  include StreetQuiz

  def show
    @street = street_draw
    @street_trail = Quizzes::Trail.call(run: @street.run)
    @trail_sections = trail_sections(@street_trail)
  end

  private

    def trail_sections(steps)
      sections = []
      current = nil
      steps.each do |step|
        if step.pack?
          current = { pack: step, questions: [] }
          sections << current
        elsif current
          current[:questions] << step
        end
      end
      sections
    end
end
