class StreetProfilesController < ApplicationController
  include StreetQuiz

  before_action :load_gate_ward, only: [ :show, :create, :update ]

  def show
    device_token
    session[:street_return] = "ward_picker" if params[:ward_next].present?
    @people_on_device = Person.on_device_anywhere(device_token).to_a
    @person = current_street_person
    if params[:person_id].present? && current_ward
      person = current_ward.people.find_by(id: params[:person_id])
      if person && @people_on_device.none? { |row| row.id == person.id }
        @claim_person = person
      end
    end
    assign_screen
    assign_merge_candidates if @screen == :edit
  end

  def create
    device_token
    @people_on_device = Person.on_device_anywhere(device_token).to_a
    ward = current_ward

    if params[:logout].present?
      clear_street_person
      forget_player
      redirect_to root_path, notice: I18n.t("flashes.signed_out")
      return
    end

    if params[:person_id].present?
      person = @people_on_device.find { |row| row.id == params[:person_id].to_i }
      person ||= ward&.people&.find(params[:person_id])
      raise People::Error.new(:missing, I18n.t("errors.people.missing")) unless person
      unless @people_on_device.any? { |row| row.id == person.id }
        person = People::Claim.call(
          ward: ward,
          person: person,
          favorite_year: params[:favorite_year],
          device_token: device_token
        )
      end
      remember_street_person(person)
      remember_ward(person.ward) if person.ward
      enter_street!(person)
      return
    end

    given = params[:name].to_s.strip
    cards = People::Recognize.call(ward: ward, given_name: given) if ward && given.present? && params[:soy_nueva].blank?
    if cards&.size == 1 && params[:favorite_year].present?
      person = cards.first.person
      if person.favorite_year == params[:favorite_year].to_i
        unless @people_on_device.any? { |row| row.id == person.id }
          person = People::Claim.call(
            ward: ward,
            person: person,
            favorite_year: params[:favorite_year],
            device_token: device_token
          )
        end
        remember_street_person(person)
        enter_street!(person)
        return
      end
    end
    if cards&.any? && params[:favorite_year].present?
      @homonym_cards = cards
      raise People::Error.new(:homonym, I18n.t("errors.people.homonym"))
    end

    person = People::Register.call(
      ward: ward,
      given_name: given,
      family_name: params[:family_name],
      avatar_key: params[:avatar_key].presence,
      favorite_year: params[:favorite_year],
      device_token: device_token
    )
    remember_street_person(person)
    enter_street!(person)
  rescue People::Error => error
    flash.now[:alert] = error.message
    @given_name = params[:name]
    @family_name = params[:family_name]
    @favorite_year = params[:favorite_year]
    @avatar_key = params[:avatar_key]
    @needs_family = error.code == :family
    @claim_person = Person.find_by(id: params[:person_id], ward_id: current_ward&.id) if params[:person_id].present?
    assign_screen(error)
    render :show, status: :unprocessable_entity
  end

  def update
    person = current_street_person
    unless person
      redirect_to street_profile_path, alert: I18n.t("flashes.profile_required")
      return
    end

    person.assign_attributes(
      given_name: params[:name].to_s.strip,
      avatar_key: params[:avatar_key]
    )

    if person.save
      person.players.update_all(name: person.given_name, avatar_key: person.avatar_key, updated_at: Time.current)
      redirect_to street_profile_path, notice: I18n.t("flashes.profile_updated")
    else
      device_token
      @people_on_device = Person.on_device_anywhere(device_token).to_a
      @person = person
      @screen = :edit
      assign_merge_candidates
      flash.now[:alert] = person.errors.full_messages.to_sentence
      render :show, status: :unprocessable_entity
    end
  end

  private

    def load_gate_ward
      return if current_ward

      @featured_ward = Ward.find_by(code: Ward::FEATURED_CODE)
    end

    def enter_street!(person)
      if (pack_id = session.delete(:pending_street_pack_id)).present?
        frame = Quizzes::StartPack.call(device_digest: street_digest, person_id: person.id, pack_id: pack_id)
        session[:street_play_run_id] = frame.run.id
        redirect_to jugar_path, notice: I18n.t("flashes.street_signed_in", name: person.given_name)
        return
      end

      if redirect_pending_duel!(person)
        return
      end

      street_return = session.delete(:street_return)
      if street_return == "ward_picker"
        redirect_to search_path(cambiar: 1), notice: I18n.t("flashes.street_signed_in", name: person.given_name)
        return
      end
      if street_return == "desafios"
        redirect_to street_challenges_path, notice: I18n.t("flashes.street_signed_in", name: person.given_name)
        return
      end

      # A player profile is useful on its own. Ward discovery is a separate,
      # explicit invitation and must not block the hub or a pending game.
      redirect_to root_path, notice: I18n.t("flashes.street_signed_in", name: person.given_name)
    end

    def redirect_pending_duel!(person)
      token = session[:pending_duel_token]
      return false if token.blank?

      duel = StreetDuel.not_expired.find_by(token:)
      return false unless duel

      Quizzes::ChallengeAccept.call(duel:, opponent_person: person, device_digest: street_digest)
      Quizzes::ViralTrack.call(
        name: "invitee_registered",
        device_digest: street_digest,
        duel:,
        person:,
        source: "invite",
        properties: { pack_id: duel.pack_id }
      )
      Quizzes::ViralTrack.call(
        name: "challenge_started",
        device_digest: street_digest,
        duel:,
        person:,
        source: "invite",
        properties: { pack_id: duel.pack_id, role: "opponent" }
      )
      session.delete(:pending_duel_token)
      redirect_to jugar_path, notice: I18n.t("flashes.street_signed_in", name: person.given_name)
      true
    rescue Quizzes::ChallengeAccept::Expired
      session.delete(:pending_duel_token)
      redirect_to root_path, alert: I18n.t("street.duel_expired")
      true
    rescue Quizzes::ChallengeAccept::Taken
      false
    end

    def assign_screen(error = nil)
      if @person && params[:edit].present?
        @screen = :edit
        return
      end

      unless current_ward
        @screen = :form
        return
      end

      @homonym_cards ||= People::Recognize.call(ward: current_ward, given_name: @given_name) if @given_name.present?

      if params[:new_profile].blank? && @people_on_device.any? && error.blank? && @claim_person.blank? && @homonym_cards.blank?
        @screen = :device
        @listed_people = @people_on_device
        return
      end

      gate = StreetProfiles::Screen.call(
        people_on_device: @people_on_device,
        current_person: @person,
        fresh: params[:new_profile].present?,
        not_me: params[:not_me].present?,
        claim_person: @claim_person,
        homonyms: error&.code == :homonym || (params[:soy_nueva].blank? && @homonym_cards.present? && params[:favorite_year].present? && params[:person_id].blank?),
        needs_family: error&.code == :family || @needs_family
      )
      @screen = gate.name
      @welcome_person = gate.person
      @listed_people = gate.people
    end

    def assign_merge_candidates
      @merge_candidates = People::MergeCandidates.call(person: @person, device_token: device_token)
    end
end
