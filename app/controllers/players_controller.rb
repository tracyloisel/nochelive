class PlayersController < ApplicationController
  before_action :set_night

  def new
    @night.reconcile!
    unless @night.open_for_registration?
      redirect_to night_path(@night.code)
      return
    end

    if current_player
      redirect_to night_path(@night.code)
      return
    end

    device_token
    @people_on_device = people_on_device.to_a
    @fresh = params[:fresh].present?
    if params[:person_id].present?
      person = @night.ward.people.find_by(id: params[:person_id])
      if person && @people_on_device.none? { |row| row.id == person.id }
        @claim_person = person
        @screen = :claim
        return
      end
    end
    assign_join_screen
  end

  def create
    @night.reconcile!
    raise People::Error.new(:closed, I18n.t("nights.closed")) unless @night.open_for_registration?

    if current_player
      redirect_to night_path(@night.code)
      return
    end

    device_token
    @people_on_device = people_on_device.to_a
    player = enter!
    remember_player(player)
    remember_ward(@night.ward)
    Rails.logger.info("session=#{@night.code} player=#{player.id} event=join")

    redirect_to night_path(@night.code)
  rescue People::Error => error
    flash.now[:alert] = error.message
    @given_name = params[:name]
    @family_name = params[:family_name]
    @favorite_year = params[:favorite_year]
    @avatar_key = params[:avatar_key]
    @needs_family = error.code == :family
    @claim_person = Person.find_by(id: params[:person_id], ward_id: @night.ward_id) if params[:person_id].present?
    assign_join_screen(error)
    render :new, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid
    redirect_to night_name_path(@night.code), alert: I18n.t("flashes.short_name")
  end

  private

    def enter!
      if params[:person_id].present?
        person = @night.ward.people.find(params[:person_id])
        unless @people_on_device.any? { |row| row.id == person.id }
          person = People::Claim.call(
            ward: @night.ward,
            person: person,
            favorite_year: params[:favorite_year],
            device_token: device_token
          )
        end
        return Players::Join.call(
          night: @night,
          name: person.given_name,
          device_token: device_token,
          person: person,
          locale: person.locale.presence || locale_preference
        )
      end

      Players::Join.call(
        night: @night,
        name: params[:name],
        device_token: device_token,
        avatar_key: params[:avatar_key],
        locale: locale_preference
      )
    end

    def assign_join_screen(error = nil)
      @people_on_device ||= []
      @homonym_cards ||= People::Recognize.call(ward: @night.ward, given_name: @given_name) if @given_name.present?

      @screen = if @claim_person
        :claim
      elsif error&.code == :homonym || (params[:soy_nueva].blank? && @homonym_cards.present? && params[:favorite_year].present? && params[:person_id].blank?)
        :homonyms
      elsif error&.code == :family || @needs_family
        :form
      elsif !@fresh && @people_on_device.one?
        :welcome
      elsif !@fresh && @people_on_device.many?
        :device
      else
        :form
      end
    end
end
