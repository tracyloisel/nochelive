module Ranks
  class Advance
    def self.call(team:)
      new(team:).call
    end

    def initialize(team:)
      @team = team
    end

    def call
      previous = @team.rank_key
      total_points = @team.score_events.sum(:points)
      total_xp = @team.score_events.sum(:xp)
      key = Team::RANKS.reverse.find { |threshold, _, _| total_xp >= threshold }&.second || "novicio"
      attrs = { cached_score: total_points, xp: total_xp, rank_key: key }
      if @team.rank_index(key) > @team.rank_index(previous)
        attrs[:pending_rank_up] = Team.rank_label_for(key)
        attrs[:next_correct_doubled] = true
      end
      @team.update!(attrs)
      unlock_chests!
      @team
    end

    private

    def unlock_chests!
      return if @team.xp < 20

      @team.reward_grants.find_or_create_by!(chest_key: "cofre_salomon") do |grant|
        grant.state = "ready"
      end
    end
  end
end
