module Scores
  class Apply
    def self.correct!(round_run, team, broadcast: true)
      new(round_run).correct!(team, broadcast: broadcast)
    end

    def self.incorrect!(round_run, team, broadcast: true)
      new(round_run).incorrect!(team, broadcast: broadcast)
    end

    def self.adjust!(night, team, points:, reason:, broadcast: true)
      ScoreEvent.award!(
        game_session: night,
        team: team,
        kind: "adjust",
        points: points,
        xp: [ points, 0 ].max,
        reason: reason
      )
      night.broadcast_state if broadcast
    end

    def initialize(round_run)
      @round_run = round_run
      @night = round_run.game_session
      @definition = round_run.definition
    end

    def correct!(team, broadcast: true)
      ApplicationRecord.transaction do
        clear_events!(team, %w[incorrect])
        unless @round_run.score_events.exists?(team: team, kind: "correct")
          if @definition.swing?
            apply_swing!(team)
          else
            apply_classic!(team)
          end

          team.update!(streak: team.streak + 1)
        end
      end
      team.recalculate_progress!
      @night.broadcast_state if broadcast
    end

    def incorrect!(team, broadcast: true)
      ApplicationRecord.transaction do
        clear_events!(team, %w[correct fastest_buzz])
        unless @round_run.score_events.exists?(team: team, kind: "incorrect")
          ScoreEvent.award!(
            game_session: @night,
            team: team,
            round_run: @round_run,
            kind: "incorrect",
            points: 0,
            xp: 0,
            reason: "scores.incorrect"
          )
        end
        team.update!(streak: 0)
      end
      team.recalculate_progress!
      @night.broadcast_state if broadcast
    end

    private

      def clear_events!(team, kinds)
        @round_run.score_events.where(team: team, kind: kinds).delete_all
      end

      def apply_swing!(team)
        points = @definition.swing_points(@night, team)
        xp = @definition.reward["xp"] || 20
        ScoreEvent.award!(
          game_session: @night,
          team: team,
          round_run: @round_run,
          kind: "correct",
          points: points,
          xp: xp,
          reason: "scores.correct"
        )
      end

      def apply_classic!(team)
        multiplier = team.next_correct_doubled? ? 2 : 1
        team.update!(next_correct_doubled: false) if multiplier > 1
        points = @definition.points * multiplier
        xp = (@definition.reward["xp"] || 20) * multiplier

        ScoreEvent.award!(
          game_session: @night,
          team: team,
          round_run: @round_run,
          kind: "correct",
          points: points,
          xp: xp,
          reason: multiplier > 1 ? "scores.crown" : "scores.correct"
        )

        return unless @round_run.first_buzz&.team_id == team.id

        ScoreEvent.award!(
          game_session: @night,
          team: team,
          round_run: @round_run,
          kind: "fastest_buzz",
          points: 5,
          xp: 8,
          reason: "scores.first_buzz"
        )
      end
  end
end
