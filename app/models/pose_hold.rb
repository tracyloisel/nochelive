class PoseHold < ApplicationRecord
  GOAL_MS = 8_000

  belongs_to :round_run
  belongs_to :team
  belongs_to :player

  def self.complete!(round_run:, team:, player:, held_ms:)
    raise "Holds are closed" unless round_run.open?

    ApplicationRecord.transaction do
      locked = RoundRun.lock.find(round_run.id)
      raise "Holds are closed" unless locked.open?

      record = lock.find_or_create_by!(round_run: locked, team: team) do |row|
        row.player = player
      end
      return record if record.finished?

      held = [ [ held_ms.to_i, 0 ].max, 60_000 ].min
      record.held_ms = held
      record.finished = held >= GOAL_MS
      record.save!
      award_if_finished!(record, locked, team)
      record
    end
  end

  def self.award_if_finished!(record, round_run, team)
    return unless record.finished?

    ScoreEvent.award!(
      game_session: round_run.game_session,
      team: team,
      round_run: round_run,
      kind: "rapid_tap",
      points: round_run.definition.points,
      xp: 16,
      reason: "Estatua sostenida"
    )
  end
  private_class_method :award_if_finished!
end
