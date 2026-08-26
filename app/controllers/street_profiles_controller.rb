class StreetProfilesController < ApplicationController
  include StreetQuiz

  before_action :load_gate_ward, only: [ :show, :create ]

  def show
    device_token
    @people_on_device = street_people_on_device.to_a
    @person = current_street_person
    if params[:person_id].present? && current_ward
      person = current_ward.people.find_by(id: params[:person_id])
      if person && @people_on_device.none? { |row| row.id == person.id }
        @claim_person = person
      end
    end
    assign_screen
  end

  def create
    device_token
    @people_on_device = street_people_on_device.to_a
    ward = current_ward
    raise People::Error.new(:ward, I18n.t("errors.people.ward")) unless ward

    if params[:guest].present?
      if session[:pending_duel_token].present?
        redirect_to root_path(ficha: 1, desafio: session[:pending_duel_token]), alert: I18n.t("street.duel_sign_in")
        return
      end
      clear_street_person
      remember_street_guest
      redirect_to root_path, notice: I18n.t("flashes.street_guest")
      return
    end

    if params[:person_id].present?
      person = ward.people.find(params[:person_id])
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

    given = params[:name].to_s.strip
    cards = People::Recognize.call(ward: ward, given_name: given) if given.present? && params[:soy_nueva].blank?
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
      avatar_key: params[:avatar_key].presence || "delfin",
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

  private

    def load_gate_ward
      return if current_ward

      @featured_ward = Ward.find_by(code: Ward::FEATURED_CODE)
    end

    def enter_street!(person)
      if redirect_pending_duel!(person)
        return
      end
      if session.delete(:street_return) == "desafios"
        redirect_to street_challenges_path, notice: I18n.t("flashes.street_signed_in", name: person.given_name)
        return
      end

      redirect_to root_path, notice: I18n.t("flashes.street_signed_in", name: person.given_name)
    end

    def redirect_pending_duel!(person)
      token = session[:pending_duel_token]
      return false if token.blank?

      duel = StreetDuel.not_expired.find_by(token:)
      return false unless duel

      Quizzes::ChallengeAccept.call(duel:, opponent_person: person, device_digest: street_digest)
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
      return unless current_ward

      @homonym_cards ||= People::Recognize.call(ward: current_ward, given_name: @given_name) if @given_name.present?

      gate = StreetProfiles::Screen.call(
        people_on_device: @people_on_device,
        current_person: @person,
        fresh: params[:fresh].present?,
        not_me: params[:not_me].present?,
        claim_person: @claim_person,
        homonyms: error&.code == :homonym || (params[:soy_nueva].blank? && @homonym_cards.present? && params[:favorite_year].present? && params[:person_id].blank?),
        needs_family: error&.code == :family || @needs_family
      )
      @screen = gate.name
      @welcome_person = gate.person
      @listed_people = gate.people
    end
end
