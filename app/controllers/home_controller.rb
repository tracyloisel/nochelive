class HomeController < ApplicationController
  include StreetQuiz

  def index
    @street = street_draw
    @street_trail = Quizzes::Trail.call(run: @street.run)
    @profile_gate = current_street_person.blank? && !street_guest?
    @gate_ward = current_ward
    @gate_people = @gate_ward ? street_people_on_device.to_a : []
    @featured_ward = Ward.find_by(code: Ward::FEATURED_CODE) unless @gate_ward
    @standings = if current_ward && current_street_person
      Quizzes::Standings.call(
        ward: current_ward,
        person: current_street_person,
        pack_id: @street.run.pack_id
      )
    end
  end
end
