module Votes
  class Tally
    def self.call(round:)
      new(round:).call
    end

    def initialize(round:)
      @round = round
    end

    def call
      return unless @round.definition.vote?

      counts = @round.ballots.group(:choice_team_id).count
      return if counts.empty?

      top = counts.values.max
      counts.select { |_id, votes| votes == top }.each_key do |team_id|
        Scores::Apply.correct!(@round, Team.find(team_id), broadcast: false)
      end
    end
  end
end
