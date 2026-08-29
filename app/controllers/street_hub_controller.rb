class StreetHubController < ApplicationController
  include StreetQuiz

  def index
    if params[:utm_source] == "organic" && params[:utm_medium] == "seo"
      Rails.logger.info("event=seo_game_entry campaign=#{params[:utm_campaign].to_s.parameterize}")
    end
    remember_device
    touch_street_presence
    @profile_gate = false
    @open_run = preferred_open_run
    @duel_campus = Quizzes::DuelCampus.call(person: current_street_person)
    @pulse = Platform::Pulse.call
    @screen = Hubs::Screen.call(
      device_digest: street_digest,
      person: current_street_person,
      ward: current_ward,
      open_run: @open_run,
      pulse: @pulse,
      random_backdrop: true,
      previous_backdrop_id: session[:hub_backdrop_id]
    )
    session[:hub_backdrop_id] = @screen.backdrop.id
    @push_prompt = night_push_prompt
  end

  def map
    remember_device
    touch_street_presence
    @world = Quizzes::World.call(device_digest: street_digest, person_id: current_street_person&.id)
    @open_run = @world.current_run if @world.current_run&.open?
    @unlock_pack_id = unlock_pack_id_param
    @screen = Hubs::Screen.call(
      device_digest: street_digest,
      person: current_street_person,
      ward: current_ward,
      open_run: @open_run,
      world: @world
    )
  end

  private

    def night_push_prompt
      return unless current_street_person
      return unless @screen.live.state.in?(%i[scheduled soon imminent])

      eligibility = Notifications::PromptEligibility.call(
        person: current_street_person,
        device_token: device_token,
        category: "nights",
        context: "live_upcoming",
        priority_blocked: @duel_campus.incoming.any? || params[:rank_up].present?
      )
      { category: "nights", context: "live_upcoming" } if eligibility.eligible
    end

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

    def preferred_open_run
      open = QuizRun.open_runs.where(device_digest: street_digest, person_id: current_street_person&.id)
      open.order(:id).last
    end
end
