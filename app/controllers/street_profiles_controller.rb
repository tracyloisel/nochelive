class StreetProfilesController < ApplicationController
  before_action :require_ward_for_profile, only: [ :show, :create ]

  def show
    device_token
    @people_on_device = street_people_on_device.to_a
    @person = current_street_person
    assign_screen
  end

  def create
    device_token
    @people_on_device = street_people_on_device.to_a

    if params[:guest].present?
      clear_street_person
      redirect_to root_path, notice: I18n.t("flashes.street_guest")
      return
    end

    if params[:person_id].present?
      person = current_ward.people.find(params[:person_id])
      unless @people_on_device.any? { |row| row.id == person.id }
        person = People::Claim.call(
          ward: current_ward,
          person: person,
          favorite_year: params[:favorite_year],
          device_token: device_token
        )
      end
      remember_street_person(person)
      redirect_to root_path, notice: I18n.t("flashes.street_signed_in", name: person.given_name)
      return
    end

    given = params[:name].to_s.strip
    cards = People::Recognize.call(ward: current_ward, given_name: given)
    if cards.any? && params[:soy_nueva].blank? && params[:favorite_year].present?
      @homonym_cards = cards
      raise People::Error.new(:homonym, I18n.t("errors.people.homonym"))
    end

    person = People::Register.call(
      ward: current_ward,
      given_name: given,
      family_name: params[:family_name],
      avatar_key: params[:avatar_key].presence || "delfin",
      favorite_year: params[:favorite_year],
      device_token: device_token
    )
    remember_street_person(person)
    redirect_to root_path, notice: I18n.t("flashes.street_signed_in", name: person.given_name)
  rescue People::Error => error
    flash.now[:alert] = error.message
    @given_name = params[:name]
    @family_name = params[:family_name]
    @favorite_year = params[:favorite_year]
    @avatar_key = params[:avatar_key]
    @needs_family = error.code == :family
    @claim_person = Person.find_by(id: params[:person_id], ward_id: current_ward.id) if params[:person_id].present?
    assign_screen(error)
    render :show, status: :unprocessable_entity
  end

  private

    def require_ward_for_profile
      return if current_ward

      redirect_to search_path, alert: I18n.t("flashes.street_ward_first")
    end

    def assign_screen(error = nil)
      @homonym_cards ||= People::Recognize.call(ward: current_ward, given_name: @given_name) if @given_name.present?

      @screen = if @claim_person
        :claim
      elsif error&.code == :homonym || (params[:soy_nueva].blank? && @homonym_cards.present? && params[:favorite_year].present? && params[:person_id].blank?)
        :homonyms
      elsif error&.code == :family || @needs_family
        :form
      elsif params[:fresh].blank? && @people_on_device.one?
        :welcome
      elsif params[:fresh].blank? && @people_on_device.many?
        :device
      else
        :form
      end
    end
end
