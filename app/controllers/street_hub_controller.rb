class StreetHubController < ApplicationController
  include StreetQuiz

  def index
    if params[:utm_source] == "organic" && params[:utm_medium] == "seo"
      Rails.logger.info("event=seo_game_entry campaign=#{params[:utm_campaign].to_s.parameterize}")
    end
    remember_device
    touch_street_presence
    @open_run = preferred_open_run
    @duel_campus = Quizzes::DuelCampus.call(person: current_street_person)
    @duel_summary = Quizzes::DuelCampusSummary.call(person: current_street_person, campus: @duel_campus)
    @screen = Hubs::Screen.call(
      device_digest: street_digest,
      person: current_street_person,
      ward: current_ward,
      open_run: @open_run
    )
    @hub_identity_state = hub_identity_state
    # A guest can play the public adventure, but must never be shown a fake
    # personal task, reading state, or Campus relationship merely to fill the
    # Hub. The short "Now" stack is therefore a signed-in member surface.
    @now_cards = if @screen.player.guest
      []
    else
      Hubs::NowCards.call(
        campus: @duel_campus,
        reading_cards: @screen.reading_cards,
        weekly_reading_cards: @screen.study&.weekly_reading_cards
      )
    end
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
    @expeditions = Expeditions::Catalog.call(
      world: @world,
      person: current_street_person,
      locale: I18n.locale
    )
    @selected_expedition = selected_expedition
    # The complete journey is the stable landing view. A selected expedition
    # only changes the view when the player explicitly asks for it (or arrives
    # through an expedition deep link); merely having published expeditions
    # must never hide the permanent map.
    @map_view = expedition_view_requested? ? :expeditions : :journey
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

    def hub_identity_state
      return if current_street_person || current_ward.nil?

      street_people_on_device.exists? ? :player_unselected : :player_missing
    end

    def unlock_pack_id_param
      id = params[:unlock].presence
      return nil unless id
      return nil unless QuizDefinition.catalog.pack_ids.include?(id)

      id
    end

    def selected_expedition
      requested = params[:expedition].to_s
      requested_expedition = @expeditions.find { |entry| entry.study_unit_id.to_s == requested || entry.id == requested } if requested.present?

      requested_expedition || @expeditions.find { |entry| entry.state == :active } || @expeditions.first
    end

    def expedition_view_requested?
      params[:view].to_s == "expeditions" || params[:expedition].present?
    end

    def preferred_open_run
      open = QuizRun.street.open_runs.where(device_digest: street_digest, person_id: current_street_person&.id)
      open.order(:id).last
    end
end
