module Identity
  extend ActiveSupport::Concern

  included do
    helper_method :current_player, :current_team, :current_person, :current_ward, :current_street_person,
                  :street_people_on_device, :street_guest?, :managed_ward, :ward_admin?,
                  :current_locale, :locale_path_for, :street_device_digest, :audience_digest,
                  :push_subscription_on_device?
  end

  private

    def set_night
      code = GameSession.normalize_code(params[:session_code] || params[:code])
      @night = GameSession.find_by_code!(code)
    end

    def current_player
      return @current_player if defined?(@current_player)
      # Resource-scoped routes (for example /quiz/:id/answers) discover their
      # night in a later before_action. Do not permanently cache the locale
      # lookup that happens before that night is available.
      return nil unless @night

      player_id = cookies.signed[:noche_player]
      token = cookies.signed[:noche_client]
      @current_player = @night.players.find_by(id: player_id, client_token: token) if player_id && token
    end

    def current_team
      current_player&.team
    end

    def current_ward
      return @current_ward if defined?(@current_ward)

      ward_id = signed_cookie(:noche_ward)
      @current_ward = Ward.find_by(id: ward_id) if ward_id
    end

    def managed_ward
      return @managed_ward if defined?(@managed_ward)

      ward_id = signed_cookie(:noche_ward_admin)
      @managed_ward = Ward.find_by(id: ward_id) if ward_id
    end

    def current_person
      current_player&.person || current_street_person
    end

    def current_street_person
      return @current_street_person if defined?(@current_street_person)

      person_id = signed_cookie(:noche_street_person)
      return @current_street_person = nil unless person_id

      person = Person.find_by(id: person_id)
      return @current_street_person = nil unless person
      return @current_street_person = nil unless PersonDevice.exists?(person:, device_token: device_token)

      @current_street_person = person
    end

    def street_people_on_device
      return Person.none unless current_ward

      Person.on_device(device_token, current_ward)
    end

    def street_guest?
      cookies.signed[:noche_street_guest].present?
    end

    def remember_street_guest
      cookies.signed[:noche_street_guest] = {
        value: "1",
        expires: 1.year,
        httponly: true,
        same_site: :lax
      }
    end

    def clear_street_guest
      cookies.delete(:noche_street_guest)
    end

    def remember_street_person(person)
      clear_street_guest
      cookies.signed[:noche_street_person] = {
        value: person.id,
        expires: 1.year,
        httponly: true,
        same_site: :lax
      }
      @current_street_person = person
    end

    def clear_street_person
      cookies.delete(:noche_street_person)
      @current_street_person = nil if defined?(@current_street_person)
    end

    def device_token
      existing = cookies.signed[:noche_device]
      return existing if existing.present?

      token = SecureRandom.urlsafe_base64(24)
      remember_device(token)
      token
    end

    def street_device_digest
      GameSession.digest_token(device_token)
    end

    def push_subscription_on_device?(person)
      person.web_push_subscriptions.active.exists?(
        device_token_digest: Notifications::Cipher.device_digest(device_token)
      )
    end

    def audience_digest
      GameSession.digest_token(audience_token)
    end

    def audience_token
      existing = cookies.signed[:noche_audience]
      return existing if existing.present?

      token = SecureRandom.urlsafe_base64(24)
      cookies.signed[:noche_audience] = {
        value: token,
        expires: 1.year,
        httponly: true,
        same_site: :lax
      }
      token
    end

    def people_on_device
      return Person.none unless @night

      Person.on_device(device_token, @night.ward)
    end

    def remember_player(player)
      cookies.signed[:noche_player] = { value: player.id, expires: 2.days, httponly: true, same_site: :lax }
      cookies.signed[:noche_client] = { value: player.client_token, expires: 2.days, httponly: true, same_site: :lax }
    end

    def forget_player
      cookies.delete(:noche_player)
      cookies.delete(:noche_client)
      @current_player = nil
    end

    def remember_device(token = nil)
      cookies.signed[:noche_device] = {
        value: token || device_token,
        expires: 1.year,
        httponly: true,
        same_site: :lax
      }
    end

    def touch_street_presence
      person = current_street_person
      return unless person

      Presences::StreetHeartbeat.call(person:, device_token: device_token)
    end

    def remember_ward(ward)
      cookies.signed[:noche_ward] = { value: ward.id, expires: 1.year, httponly: true, same_site: :lax }
      @current_ward = ward
    end

    def remember_ward_admin(ward)
      remember_ward(ward)
      cookies.signed[:noche_ward_admin] = { value: ward.id, expires: 1.year, httponly: true, same_site: :lax }
    end

    def remember_locale(locale)
      cookies[Locale::COOKIE] = {
        value: Locale.cast(locale),
        expires: 1.year,
        httponly: true,
        same_site: :lax
      }
    end

    def current_locale
      if request.get? && params[:locale].present?
        return Locale.i18n(params[:locale])
      end

      Locale.i18n(locale_preference)
    end

    def locale_preference
      return current_player.locale if current_player&.locale.present?
      return cookies[Locale::COOKIE] if cookies[Locale::COOKIE].present?

      Locale.from_accept_language(request.env["HTTP_ACCEPT_LANGUAGE"])
    end

    def locale_path_for
      if @night
        night_locale_path(@night.code)
      else
        locale_path
      end
    end

    def signed_cookie(name)
      cookies.signed[name]
    rescue NoMethodError => error
      raise unless error.message.include?("generate_key")
      nil
    end

    def ward_admin?(ward = current_ward)
      managed_ward.present? && ward.present? && managed_ward.id == ward.id
    end

    def require_player
      player = current_player
      if player&.person.present? && player.person.ward_id != @night.ward_id
        forget_player
        redirect_to night_name_path(@night.code), alert: I18n.t("flashes.profile_required")
        return
      end

      redirect_to night_name_path(@night.code) unless player
    end

    def require_team
      unless current_player
        redirect_to night_name_path(@night.code)
        return
      end

      return if current_team
      redirect_to night_play_path(@night.code)
    end

    def require_participant_profile
      return if current_player&.person.present?

      redirect_to night_name_path(@night.code), alert: I18n.t("flashes.profile_required")
    end

    def require_ward
      return if current_ward

      redirect_to root_path
    end

    def require_street_identity
      person = current_street_person
      unless person
        redirect_to street_profile_path(quick: 1), alert: I18n.t("flashes.profile_required")
        return
      end

      remember_ward(person.ward) if person.ward && current_ward&.id != person.ward_id
    end

    def require_explicit_street_identity
      person = current_street_person
      unless person
        redirect_to street_profile_path(quick: 1), alert: I18n.t("flashes.profile_required")
        return
      end

      unless params[:player_id].to_s == person.id.to_s
        head :not_found
        return
      end

      @requested_street_person = person
      remember_ward(person.ward) if person.ward && current_ward&.id != person.ward_id
    end

    def require_ward_admin
      return if managed_ward

      if current_ward
        redirect_to ward_profile_path(current_ward.code), alert: I18n.t("flashes.open_ward_first")
      else
        redirect_to ward_gate_path, alert: I18n.t("flashes.open_ward_first")
      end
    end
end
