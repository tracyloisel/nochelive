module Players
  class Join
    def self.call(night:, name:, device_token:, person: nil, avatar_key: nil, locale: nil)
      new(night:, name:, device_token:, person:, avatar_key:, locale:).call
    end

    def initialize(night:, name:, device_token:, person:, avatar_key:, locale:)
      @night = night
      @name = name.to_s.strip.first(24)
      @device_token = device_token
      @person = person
      @avatar_key = avatar_key
      @locale = Locale.cast(locale.presence || person&.locale)
    end

    def call
      raise People::Error.new(:name, I18n.t("errors.people.name")) if @name.blank? && @person.blank?

      if @person
        existing = @night.players.find_by(person_id: @person.id)
        if existing
          return existing
        end
      end

      player = @night.players.create!(
        person: @person,
        name: @person&.given_name || @name,
        client_token: SecureRandom.uuid,
        avatar_key: @person&.avatar_key || safe_avatar,
        device_token: @device_token,
        locale: @locale,
        last_seen_at: Time.current
      )

      if @person && @device_token.present?
        PersonDevice.find_or_create_by!(person: @person, device_token: @device_token) do |row|
          row.last_seen_at = Time.current
        end
      end

      Nights::Events.emit(
        night: @night,
        kind: "join",
        dedupe_key: "join:#{player.id}",
        payload: { player_id: player.id, player_name: player.name }
      )
      player
    end

    private

      def safe_avatar
        Player::AVATARS.include?(@avatar_key.to_s) ? @avatar_key : "delfin"
      end

  end
end
