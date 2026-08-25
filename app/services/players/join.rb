module Players
  class Join
    def self.call(night:, name:, role:, location:, device_token:, person: nil, avatar_key: nil)
      new(night:, name:, role:, location:, device_token:, person:, avatar_key:).call
    end

    def initialize(night:, name:, role:, location:, device_token:, person:, avatar_key:)
      @night = night
      @name = name.to_s.strip.first(24)
      @role = role
      @location = location
      @device_token = device_token
      @person = person
      @avatar_key = avatar_key
    end

    def call
      raise People::Error.new(:name, "Escribe un nombre corto.") if @name.blank? && @person.blank?

      if @person
        existing = @night.players.find_by(person_id: @person.id)
        return existing if existing
      end

      player = @night.players.create!(
        person: @person,
        name: @person&.given_name || @name,
        role: @role,
        location: @location,
        client_token: SecureRandom.uuid,
        avatar_key: @person&.avatar_key || safe_avatar,
        device_token: @device_token,
        last_seen_at: Time.current
      )
      Teams::Seat.call(night: @night, player: player) if player.participant? && player.remote?

      if @person && @device_token.present?
        PersonDevice.find_or_create_by!(person: @person, device_token: @device_token) do |row|
          row.last_seen_at = Time.current
        end
      end

      if player.spectator?
        Nights::BroadcastPresence.call(night: @night)
      else
        @night.broadcast_state
      end
      player
    end

    private

      def safe_avatar
        Player::AVATARS.include?(@avatar_key.to_s) ? @avatar_key : "delfin"
      end
  end
end
