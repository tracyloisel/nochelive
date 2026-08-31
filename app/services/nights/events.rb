module Nights
  class Events
    def self.emit(night:, kind:, dedupe_key:, payload: {})
      event = night.live_events.create_or_find_by!(dedupe_key:) do |row|
        row.kind = kind
        row.payload = payload
        row.occurred_at = Time.current
      end
      Nights::BroadcastJob.perform_later(night.id, event.id) if event.previously_new_record?
      event
    end

    def self.after_answer(run:, answer:, previous_score:)
      night = run.game_session
      new_events = []
      payload = {
        player_id: run.player_id,
        player_name: run.player.name,
        team_id: run.team_id,
        team_name: run.team.name,
        points: answer.points_awarded.to_i
      }

      transaction = ->(kind, key, extra = {}) do
        event = night.live_events.create_or_find_by!(dedupe_key: key) do |row|
          row.kind = kind
          row.payload = payload.merge(extra)
          row.occurred_at = Time.current
        end
        new_events << event if event.previously_new_record?
      end

      LiveEvent.transaction do
        transaction.call("correct", "correct:#{answer.id}") if answer.correct?
        if answer.correct? && [ 3, 5, 10 ].include?(answer.streak_after.to_i)
          transaction.call("streak", "streak:#{answer.id}", streak: answer.streak_after.to_i)
        end

        gained = run.score.to_i - previous_score.to_i
        if gained.positive?
          teams = night.teams.order(:name).pluck(:id, :name)
          after_scores = night.quiz_runs.group(:team_id).sum(:score)
          before_scores = after_scores.merge(run.team_id => after_scores[run.team_id].to_i - gained)
          before_leader = leader_id(teams:, scores: before_scores)
          after_leader = leader_id(teams:, scores: after_scores)
          if after_leader == run.team_id && after_leader != before_leader
            transaction.call("lead_change", "lead:#{answer.id}")
          end
        end
      end

      Nights::BroadcastJob.perform_later(night.id, new_events.last.id) if new_events.any?
      new_events
    end

    def self.leader_id(teams:, scores:)
      teams.min_by { |id, name| [ -scores[id].to_i, name ] }&.first
    end
    private_class_method :leader_id
  end
end
