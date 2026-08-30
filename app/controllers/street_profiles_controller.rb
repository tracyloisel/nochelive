class StreetProfilesController < ApplicationController
  include StreetQuiz

  EDITOR_KEYS = %w[given_name family_name avatar_key favorite_year locale merge].freeze

  before_action :load_gate_ward, only: [ :show, :create, :update ]
  before_action :require_explicit_street_identity, if: :explicit_profile_action?

  def show
    device_token
    session[:street_return] = "ward_picker" if params[:ward_next].present?
    @people_on_device = Person.on_device_anywhere(device_token).to_a
    @person = @requested_street_person || current_street_person
    if explicit_profile_request?
      if params[:ward_next].present?
        session[:street_return] = "profile"
        redirect_to search_path(cambiar: 1)
        return
      end

      @screen = :profile
      assign_profile
      return
    end
    if params[:person_id].present? && current_ward
      person = current_ward.people.find_by(id: params[:person_id])
      if person && @people_on_device.none? { |row| row.id == person.id }
        @claim_person = person
      end
    end
    if @person && params[:ward_next].present?
      session[:street_return] = "profile"
      redirect_to search_path(cambiar: 1)
      return
    end
    if redirect_gate_to_explicit_profile?
      redirect_to player_profile_path(@person, **legacy_profile_query)
      return
    end
    assign_screen
    assign_profile if @screen == :profile
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
    person = @requested_street_person

    updates = profile_updates
    @submitted_profile_updates = updates.dup
    if updates.key?(:locale)
      locale = updates.delete(:locale)
      Locales::Set.call(locale:, person: person)
      remember_locale(locale)
    end
    People::Update.call(person:, **updates) if updates.any?
    redirect_to player_profile_path(person), notice: I18n.t("flashes.profile_updated")
  rescue People::Error, ActiveRecord::RecordInvalid => error
    device_token
    @people_on_device = Person.on_device_anywhere(device_token).to_a
    @person = person
    @screen = :profile
    @editor_key = editor_for_update
    @profile_error = error.message
    assign_profile
    render :show, status: :unprocessable_entity
  end

  private

    def load_gate_ward
      return if current_ward

      @featured_ward = Ward.find_by(code: Ward::FEATURED_CODE)
    end

    def explicit_profile_request?
      params[:player_id].present?
    end

    def explicit_profile_action?
      action_name == "update" || explicit_profile_request?
    end

    def redirect_gate_to_explicit_profile?
      @person.present? && params[:not_me].blank? && params[:new_profile].blank? && params[:fresh].blank? && params[:person_id].blank?
    end

    def legacy_profile_query
      params.permit(:edit, :locale).to_h.symbolize_keys
    end

    def enter_street!(person)
      if (pack_id = session.delete(:pending_street_pack_id)).present?
        frame = Quizzes::StartPack.call(device_digest: street_digest, person_id: person.id, pack_id: pack_id)
        session[:street_play_run_id] = frame.run.id
        redirect_to jugar_path, notice: I18n.t("flashes.street_signed_in", name: person.given_name)
        return
      end

      if redirect_pending_duel_invitation!(person)
        return
      end

      street_return = session.delete(:street_return)
      if street_return == "notification_settings"
        redirect_to notification_settings_path, notice: I18n.t("flashes.street_signed_in", name: person.given_name)
        return
      end
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

    def redirect_pending_duel_invitation!(person)
      token = session[:pending_duel_invitation_token]
      return false if token.blank?

      invitation = DuelInvitation.find_by_token(token)
      return false unless invitation&.available?

      result = Quizzes::DuelInvitationClaim.call(invitation:, person:, device_digest: street_digest)
      Quizzes::ViralTrack.call(
        name: "invitee_profile_created",
        device_digest: street_digest,
        invitation:,
        duel: result.duel,
        person:,
        source: "invite",
        event_key: "invitee-profile-created:#{invitation.id}:#{person.id}"
      )
      frame = Quizzes::Draw.call(device_digest: street_digest, person_id: person.id, ward: person.ward)
      session[:street_play_run_id] = frame.run.id
      session.delete(:pending_duel_invitation_token)
      redirect_to jugar_path, notice: I18n.t("flashes.street_signed_in", name: person.given_name)
      true
    rescue Quizzes::DuelInvitationClaim::Expired
      session.delete(:pending_duel_invitation_token)
      redirect_to root_path, alert: I18n.t("duel_campus.errors.expired")
      true
    rescue Quizzes::DuelInvitationClaim::Taken
      false
    end

    def assign_screen(error = nil)
      if @person && params[:not_me].blank? && params[:new_profile].blank? && error.blank?
        @screen = :profile
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

    def assign_profile
      @snapshot = StreetProfiles::Snapshot.call(person: @person)
      @editor_key ||= EDITOR_KEYS.include?(params[:edit].to_s) ? params[:edit].to_s : nil
      assign_merge_candidates if @editor_key == "merge"
    end

    def profile_updates
      updates = {}
      updates[:given_name] = params[:given_name] if params.key?(:given_name)
      updates[:given_name] = params[:name] if !updates.key?(:given_name) && params.key?(:name)
      updates[:family_name] = params[:family_name] if params.key?(:family_name)
      updates[:avatar_key] = params[:avatar_key] if params.key?(:avatar_key)
      updates[:favorite_year] = params[:favorite_year] if params.key?(:favorite_year)
      updates[:locale] = params[:locale] if params.key?(:locale)
      raise People::Error.new(:missing, I18n.t("errors.people.missing")) if updates.empty?

      updates
    end

    def editor_for_update
      profile_updates.keys.first.to_s.presence_in(EDITOR_KEYS)
    rescue People::Error
      nil
    end
end
