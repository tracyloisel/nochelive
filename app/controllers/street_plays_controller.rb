class StreetPlaysController < ApplicationController
  include StreetQuiz

  def show
    remember_device
    touch_street_presence
    @run = QuizRun.open_runs
      .where(device_digest: street_digest, person_id: current_street_person&.id)
      .order(:id)
      .last
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
    @rival = if current_ward
      Quizzes::Rival.call(ward: current_ward, person: current_street_person, pack_id: @run.pack_id)
    end
    @duel = Quizzes::Complete.active_duel_for(@run) if @run.finished?
    @play_context = :jugar
  end
end
