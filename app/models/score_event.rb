class ScoreEvent < ApplicationRecord
  belongs_to :game_session
  belongs_to :team
  belongs_to :round_run, optional: true

  KINDS = %w[correct incorrect fastest_buzz rapid_tap participation adjust chest].freeze

  validates :kind, :reason, presence: true
  validates :kind, inclusion: { in: KINDS }

  after_commit :refresh_team

  def self.award!(game_session:, team:, kind:, points:, xp:, reason:, round_run: nil)
    event = nil
    ApplicationRecord.transaction do
      event = create!(
        game_session: game_session,
        team: team,
        round_run: round_run,
        kind: kind,
        points: points,
        xp: xp,
        reason: reason
      )
    rescue ActiveRecord::RecordNotUnique
      event = find_by!(round_run: round_run, team: team, kind: kind)
    end
    event
  end

  private

  def refresh_team
    team.recalculate_progress!
  end
end
