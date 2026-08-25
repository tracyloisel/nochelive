module Identity
  extend ActiveSupport::Concern

  included do
    helper_method :current_player, :current_team, :current_person, :current_ward, :hosted_ward, :presenter_for?, :ward_presenter?, :ward_host?, :current_locale, :locale_path_for
  end

  private

    def set_night
      code = GameSession.normalize_code(params[:session_code] || params[:code])
      @night = GameSession.find_by!(code: code)
    end

    def current_player
      return @current_player if defined?(@current_player)
      return @current_player = nil unless @night

      player_id = cookies.signed[:noche_player]
      token = cookies.signed[:noche_client]
      @current_player = @night.players.find_by(id: player_id, client_token: token) if player_id && token
    end

    def current_team
      current_player&.team
    end

    def current_ward
      return @current_ward if defined?(@current_ward)

      ward_id = cookies.signed[:noche_ward]
      @current_ward = Ward.find_by(id: ward_id) if ward_id
    end

    def hosted_ward
      return @hosted_ward if defined?(@hosted_ward)

      ward_id = cookies.signed[:noche_ward_host]
      @hosted_ward = Ward.find_by(id: ward_id) if ward_id
    end

    def current_person
      current_player&.person
    end

    def device_token
      existing = cookies.signed[:noche_device]
      return existing if existing.present?

      token = SecureRandom.urlsafe_base64(24)
      remember_device(token)
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

    def remember_device(token = nil)
      cookies.signed[:noche_device] = {
        value: token || device_token,
        expires: 1.year,
        httponly: true,
        same_site: :lax
      }
    end

    def remember_presenter(night)
      cookies.signed[:noche_presenter] = { value: night.id, expires: 1.day, httponly: true, same_site: :lax }
    end

    def remember_ward(ward)
      cookies.signed[:noche_ward] = { value: ward.id, expires: 1.year, httponly: true, same_site: :lax }
    end

    def remember_ward_host(ward)
      remember_ward(ward)
      cookies.signed[:noche_ward_host] = { value: ward.id, expires: 1.year, httponly: true, same_site: :lax }
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
      Locale.i18n(locale_preference)
    end

    def locale_preference
      return current_player.locale if current_player&.locale.present?
      return @night.presenter_locale if @night && presenter_for?(@night) && @night.presenter_locale.present?
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

    def presenter_for?(night)
      return false unless cookies.signed[:noche_presenter].to_i == night.id
      return true if night.presenter_device_digest.blank?

      token = cookies.signed[:noche_device].to_s
      token.present? && night.presenter_held_by?(token)
    end

    def ward_presenter?
      hosted_ward.present?
    end

    def ward_host?(ward = current_ward)
      hosted_ward.present? && ward.present? && hosted_ward.id == ward.id
    end

    def require_player
      redirect_to night_name_path(@night.code) unless current_player
    end

    def require_team
      return if current_team
      redirect_to night_play_path(@night.code)
    end

    def require_presenter
      expire_pending_presenter_claim
      if presenter_for?(@night)
        if @night.presenter_device_digest.blank?
          Presenters::Seat.call(night: @night, device_token: device_token)
        end
        return
      end

      redirect_to presenter_gate_path(@night.code), alert: I18n.t("flashes.presenter_required")
    end

    def expire_pending_presenter_claim
      return unless @night

      claim = @night.pending_presenter_claim
      return unless claim&.pending?

      expired = Presenters::Expire.call(claim: claim)
      @night.reload if expired&.granted?
    end

    def require_ward
      return if current_ward

      redirect_to root_path
    end

    def require_ward_presenter
      return if hosted_ward

      if current_ward
        redirect_to ward_profile_path(current_ward.code), alert: I18n.t("flashes.open_ward_first")
      else
        redirect_to ward_gate_path, alert: I18n.t("flashes.open_ward_first")
      end
    end
end
