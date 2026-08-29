class HomeController < ApplicationController
  include StreetQuiz

  def index
    @street = street_draw
    @profile_gate = current_street_person.blank? && !street_guest?
    @gate_ward = current_ward
    @gate_people = @gate_ward ? street_people_on_device.to_a : []
    if @profile_gate && @gate_ward
      gate = StreetProfiles::Screen.call(
        people_on_device: @gate_people,
        current_person: current_street_person,
        fresh: params[:fresh].present?,
        not_me: params[:not_me].present?
      )
      @gate_screen = gate.name
      @gate_person = gate.person
      @gate_people = gate.people
    end
    @featured_ward = Ward.find_by(code: Ward::FEATURED_CODE) unless @gate_ward
    if @profile_gate && @gate_ward.blank?
      @search = Wards::Search.call(query: "")
      @wards = @search.wards
      @pick_url = street_ward_pick_path
      @picker_pick = "rama"
    end
    @standings = if current_ward && current_street_person
      Quizzes::Standings.call(
        ward: current_ward,
        person: current_street_person,
        pack_id: @street.run.pack_id
      )
    end
  end
end
