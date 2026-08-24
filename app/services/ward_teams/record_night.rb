module WardTeams
  class RecordNight
    def self.call(night:)
      new(night:).call
    end

    def initialize(night:)
      @night = night
    end

    def call
      return @night if @night.season_applied_at.present?

      ApplicationRecord.transaction do
        locked = GameSession.lock.find(@night.id)
        return locked if locked.season_applied_at.present?

        locked.teams.includes(:ward_team).find_each do |team|
          next unless team.ward_team

          label = team.ward_team.apply_night_xp!(team.xp)
          team.update!(season_rank_up: label) if label
        end
        locked.update!(season_applied_at: Time.current)
        locked
      end
    end
  end
end
