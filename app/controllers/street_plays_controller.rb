class StreetPlaysController < ApplicationController
  include StreetQuiz

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
    @rival = if current_ward
      Quizzes::Rival.call(ward: current_ward, person: current_street_person, pack_id: @run.pack_id)
    end
    @duel = Quizzes::Complete.duel_for(@run)
    @play_context = :jugar
  end

  private

    def preferred_street_run
      open = QuizRun.open_runs.where(device_digest: street_digest, person_id: current_street_person&.id)
      person = current_street_person
      if person
        duel = StreetDuel.active.not_expired
          .where("challenger_person_id = :id OR opponent_person_id = :id", id: person.id)
          .order(:id)
          .last
        if duel
          run_id = person.id == duel.challenger_person_id ? duel.challenger_run_id : duel.opponent_run_id
          match = open.find_by(id: run_id) if run_id
          return match if match
        end
      end
      pinned = session[:street_play_run_id]
      match = open.find_by(id: pinned) if pinned
      return match if match

      open.order(:id).last
    end
end
