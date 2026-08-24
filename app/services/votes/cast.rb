module Votes
  class Cast
    def self.call(round:, team:, player:, choice:)
      new(round:, team:, player:, choice:).call
    end

    def initialize(round:, team:, player:, choice:)
      @round = round
      @team = team
      @player = player
      @choice = choice
    end

    def call
      ballot = persist!
      @round.game_session.broadcast_state(pulse: { kind: "answer", player: @player })
      ballot
    end

    private

    def persist!
      raise "Not a vote" unless @round.definition.vote?
      raise "Votes are closed" unless @round.open?
      raise "Own team" if @choice.id == @team.id
      raise "Unknown team" unless @round.game_session.teams.exists?(id: @choice.id)

      ApplicationRecord.transaction do
        locked = RoundRun.lock.find(@round.id)
        raise "Votes are closed" unless locked.open?

        existing = Ballot.find_by(round_run: locked, player: @player)
        return existing if existing

        ballot = Ballot.create!(round_run: locked, team: @team, player: @player, choice_team: @choice)
        if all_voted?(locked)
          locked.lock!
          Votes::Tally.call(round: locked)
        end
        ballot
      end
    end

    def all_voted?(round)
      voters = round.game_session.players.joins(:team_membership).where(role: "participant")
      voters.any? && voters.all? { |player| Ballot.exists?(round_run: round, player:) }
    end
  end
end
