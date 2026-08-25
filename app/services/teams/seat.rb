module Teams
  class Seat
    def self.call(night:, player:)
      new(night:, player:).call
    end

    def initialize(night:, player:)
      @night = night
      @player = player
    end

    def call
      raise People::Error.new(:location, "En casa juegas solo.") unless @player.remote?
      raise People::Error.new(:role, "Los espectadores no juegan.") unless @player.participant?

      team = ApplicationRecord.transaction do
        locked = Player.lock.find(@player.id)
        if (existing = locked.team)&.solo?
          existing
        else
          locked.team_membership&.destroy
          created = @night.teams.create!(name: unique_name, emblem: pick_emblem, solo: true)
          TeamMembership.create!(player: locked, team: created)
          created
        end
      end
      @player.reload
      team
    end

    private

      def unique_name
        base = @player.name.to_s.strip.first(28)
        base = "Casa" if base.blank?
        return base unless @night.teams.exists?(name: base)

        2.upto(20) do |n|
          suffix = " · #{n}"
          candidate = "#{base.first(28 - suffix.length)}#{suffix}"
          return candidate unless @night.teams.exists?(name: candidate)
        end

        "#{base.first(20)} · #{SecureRandom.hex(3)}"
      end

      def pick_emblem
        used = @night.teams.pluck(:emblem)
        (Team::EMBLEMS.keys - used).first || Team::EMBLEMS.keys.sample
      end
  end
end
