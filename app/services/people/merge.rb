module People
  class Merge
    def self.call(keeper:, source:)
      new(keeper:, source:).call
    end

    def initialize(keeper:, source:)
      @keeper = keeper
      @source = source
    end

    def call
      raise Error.new(:ward, I18n.t("errors.people.merge_ward")) if @keeper.ward_id != @source.ward_id
      raise Error.new(:same, I18n.t("errors.people.merge_same")) if @keeper.id == @source.id

      ApplicationRecord.transaction do
        @keeper.lock!
        @source.lock!
        move_players!
        move_devices!
        move_viral_events!
        @keeper.last_ward_team ||= @source.last_ward_team
        @keeper.save!
        @source.destroy!
      end
      @keeper
    end

    private

      def move_players!
        @source.players.find_each do |player|
          if Player.exists?(game_session_id: player.game_session_id, person_id: @keeper.id)
            player.update!(person: nil)
          else
            player.update!(person: @keeper, name: @keeper.given_name, avatar_key: @keeper.avatar_key)
          end
        end
      end

      def move_devices!
        @source.person_devices.find_each do |row|
          if @keeper.person_devices.exists?(device_token: row.device_token)
            row.destroy!
          else
            row.update!(person: @keeper)
          end
        end
      end

      def move_viral_events!
        @source.viral_events.update_all(person_id: @keeper.id, updated_at: Time.current)
      end
  end
end
