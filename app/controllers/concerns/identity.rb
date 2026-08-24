module Identity
  extend ActiveSupport::Concern

  included do
    helper_method :current_player, :current_team, :current_person, :current_ward, :presenter_for?, :ward_presenter?
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

    def presenter_for?(night)
      cookies.signed[:noche_presenter].to_i == night.id
    end

    def ward_presenter?
      current_ward.present?
    end

    def require_player
      redirect_to night_name_path(@night.code) unless current_player
    end

    def require_team
      return if current_team
      redirect_to night_play_path(@night.code)
    end

    def require_presenter
      return if presenter_for?(@night)
      redirect_to presenter_gate_path(@night.code), alert: "Necesitas el enlace del presentador."
    end

    def require_ward
      return if current_ward

      redirect_to new_ward_path
    end
end
