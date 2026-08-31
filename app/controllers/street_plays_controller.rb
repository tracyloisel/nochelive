class StreetPlaysController < ApplicationController
  include StreetQuiz

  before_action :require_street_identity

  def show
    remember_device
    touch_street_presence
    @run = preferred_street_run
    unless @run
      redirect_to root_path
      return
    end

    @street = Quizzes::Draw.frame(@run, ward: current_ward)
    @world = Quizzes::World.call(device_digest: street_digest, person_id: current_street_person&.id)
    @standings = if current_ward && current_street_person
      Quizzes::Standings.call(
        ward: current_ward,
        person: current_street_person,
        pack_id: @run.pack_id
      )
    end
    @duel_campus = Quizzes::DuelCampus.call(person: current_street_person, run: @run)
    @play_context = :jugar
  end

  private

    def preferred_street_run
      open = QuizRun.street.open_runs.where(device_digest: street_digest, person_id: current_street_person&.id)
      pinned = session[:street_play_run_id]
      match = open.find_by(id: pinned) if pinned
      return match if match

      open.order(:id).last
    end
end
