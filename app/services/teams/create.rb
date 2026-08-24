module Teams
  class Create
    def self.call(night:, name:, emblem:, player: nil)
      new(night:, name:, emblem:, player:).call
    end

    def initialize(night:, name:, emblem:, player:)
      @night = night
      @name = name.to_s.strip.first(28)
      @emblem = emblem
      @player = player
    end

    def call
      raise People::Error.new(:name, "Ese equipo ya existe. Únete a él.") if @name.blank?

      emblem = Team::EMBLEMS.key?(@emblem.to_s) ? @emblem.to_s : Team::EMBLEMS.keys.sample
      team = ApplicationRecord.transaction do
        ward_team = @night.ward.ward_teams.find_or_create_by!(name: @name) do |row|
          row.emblem = emblem
        end
        created = @night.teams.create!(name: @name, emblem: ward_team.emblem, ward_team:)
        if @player
          Memberships::Join.call(night: @night, player: @player, team: created)
        end
        created
      end
      @night.broadcast_state unless @player
      team
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      raise People::Error.new(:taken, "Ese equipo ya existe. Únete a él.")
    end
  end
end
