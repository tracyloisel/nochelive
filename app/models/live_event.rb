class LiveEvent < ApplicationRecord
  KINDS = %w[join team_join quiz_start correct streak lead_change quiz_finish night_open night_close].freeze

  belongs_to :game_session

  validates :kind, :dedupe_key, :occurred_at, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :dedupe_key, uniqueness: { scope: :game_session_id }

  scope :recent_first, -> { order(occurred_at: :desc, id: :desc) }
end
