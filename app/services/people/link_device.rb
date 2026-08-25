module People
  class LinkDevice
    def self.call(night:, player:, person:)
      new(night:, player:, person:).call
    end

    def initialize(night:, player:, person:)
      @night = night
      @player = player
      @person = person
    end

    def call
      raise Error.new(:ward, I18n.t("errors.people.ward")) unless @person.ward_id == @night.ward_id
      raise Error.new(:player, I18n.t("errors.people.player")) unless @player.game_session_id == @night.id

      ApplicationRecord.transaction do
        @player.update!(person: @person, name: @person.given_name, avatar_key: @person.avatar_key)
        if @player.device_token.present?
          PersonDevice.find_or_create_by!(person: @person, device_token: @player.device_token) do |row|
            row.last_seen_at = Time.current
          end
        end
      end
      @player
    end
  end
end
