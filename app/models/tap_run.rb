class TapRun < ApplicationRecord
  belongs_to :round_run
  belongs_to :team
  belongs_to :player

  def self.tap!(round_run:, team:, player:)
    raise "Taps are closed" unless round_run.accepting_taps?

    ApplicationRecord.transaction do
      locked = RoundRun.lock.find(round_run.id)
      raise "Taps are closed" unless locked.accepting_taps?

      run = lock.find_or_create_by!(round_run: locked, team: team) do |record|
        record.player = player
        record.taps = 0
      end

      return run if run.finished?

      goal = locked.definition.tap_goal
      run.taps += 1
      run.finished = run.taps >= goal
      run.save!
      award_if_finished!(run, locked, team)
      run
    end
  end

  def self.award_if_finished!(run, round_run, team)
    return unless run.finished?

    points = round_run.definition.points_max
    ScoreEvent.award!(
      game_session: round_run.game_session,
      team: team,
      round_run: round_run,
      kind: "rapid_tap",
      points: points,
      xp: 16,
      reason: "scores.stone"
    )
  end
  private_class_method :award_if_finished!
end
