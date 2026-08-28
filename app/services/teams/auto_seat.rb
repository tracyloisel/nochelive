module Teams
  class AutoSeat
    def self.call(night:, player:)
      new(night:, player:).call
    end

    def initialize(night:, player:)
      @night = night
      @player = player
    end

    def call
      raise People::Error.new(:role, I18n.t("errors.people.role")) unless @player.participant?
      return Teams::Seat.call(night: @night, player: @player) if @player.remote?

      ApplicationRecord.transaction do
        player = Player.lock.find(@player.id)
        return player.team if player.team&.chapel?

        team = preferred_team(player) || balanced_team || create_fallback_team
        player.team_membership&.destroy
        TeamMembership.create!(player: player, team: team)
        player.person.update!(last_ward_team: team.ward_team) if player.person && team.ward_team
        team
      end
    ensure
      @player.reload if @player.persisted?
    end

    private

      def preferred_team(player)
        ward_team = player.person&.last_ward_team
        return unless ward_team

        @night.teams.chapel.find_by(ward_team: ward_team)
      end

      def balanced_team
        teams = @night.teams.chapel
          .left_joins(:team_memberships)
          .group(:id)
          .order(Arel.sql("COUNT(team_memberships.id) ASC"), :id)
          .to_a

        return if teams.empty?

        # A night without configured ward teams still needs two opposing seats;
        # otherwise every arrival would be merged into the same fallback team.
        if teams.one? && teams.first.ward_team_id.blank? && teams.first.players.participants.exists?
          return
        end

        teams.first
      end

      def create_fallback_team
        @night.teams.create!(
          name: unique_fallback_name,
          emblem: available_emblem,
          solo: false
        )
      end

      def unique_fallback_name
        base = I18n.t("play.auto_team_name")
        return base unless @night.teams.exists?(name: base)

        2.upto(20) do |number|
          candidate = "#{base} #{number}"
          return candidate unless @night.teams.exists?(name: candidate)
        end
        "#{base} · #{SecureRandom.hex(2)}"
      end

      def available_emblem
        used = @night.teams.pluck(:emblem)
        (Team::EMBLEMS.keys - used).first || Team::EMBLEMS.keys.first
      end
  end
end
