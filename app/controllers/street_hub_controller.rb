class StreetHubController < ApplicationController
  include StreetQuiz

  def index
    remember_device
    touch_street_presence
    clear_street_guest if params[:ficha].present?
    @world = Quizzes::World.call(device_digest: street_digest, person_id: current_street_person&.id)
    @profile_gate = params[:ficha].present? || (current_street_person.blank? && !street_guest?)
    @gate_ward = current_ward
    @gate_people = @gate_ward ? street_people_on_device.to_a : []
    assign_profile_identity if @profile_gate && @gate_ward
    @featured_ward = Ward.find_by(code: Ward::FEATURED_CODE) unless @gate_ward
    @streak = Quizzes::Streak.call(person_id: current_street_person&.id)
    @standings = if current_ward && current_street_person
      Quizzes::Standings.call(ward: current_ward, person: current_street_person)
    end
    @rival = if current_ward && current_street_person
      Quizzes::Rival.call(ward: current_ward, person: current_street_person)
    end
    @challenge = load_challenge
    @pending_duel = @challenge&.duel
    @open_run = preferred_open_run
    @unlock_pack_id = unlock_pack_id_param
    assign_ward_picker if @profile_gate && @gate_ward.blank?
  end

  private

    def assign_profile_identity
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

    def assign_ward_picker
      @search = Wards::Search.call(query: "")
      @wards = @search.wards
      @pick_url = street_ward_pick_path
      @picker_pick = "rama"
    end

    def unlock_pack_id_param
      id = params[:unlock].presence
      return nil unless id
      return nil unless QuizDefinition.catalog.pack_ids.include?(id)

      id
    end

    def load_challenge
      explicit = params[:desafio].presence || params[:token].presence
      token = explicit || session[:pending_duel_token].presence
      screen = Quizzes::ChallengeScreen.call(person: current_street_person, token:)
      return unless screen
      return if screen.phase == :taken

      pin_challenge_token!(screen, explicit)
      screen
    end

    def pin_challenge_token!(screen, explicit)
      own_outgoing = screen.role == :challenger
      done = screen.phase == :result
      if own_outgoing || done
        session.delete(:pending_duel_token) if session[:pending_duel_token] == screen.duel.token
      elsif explicit.present? && screen.phase == :accept
        session[:pending_duel_token] = screen.duel.token
      end
    end

    def preferred_open_run
      open = QuizRun.open_runs.where(device_digest: street_digest, person_id: current_street_person&.id)
      person = current_street_person
      if person && @challenge
        duel = @challenge.duel
        run_id = person.id == duel.challenger_person_id ? duel.challenger_run_id : duel.opponent_run_id
        match = open.find_by(id: run_id) if run_id
        return match if match
      end
      open.order(:id).last
    end
end
