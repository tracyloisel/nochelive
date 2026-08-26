class StreetDuel < ApplicationRecord
  STATUSES = %w[pending challenger_done opponent_done resolved].freeze

  belongs_to :challenger_person, class_name: "Person"
  belongs_to :opponent_person, class_name: "Person", optional: true
  belongs_to :ward
  belongs_to :challenger_run, class_name: "QuizRun", optional: true
  belongs_to :opponent_run, class_name: "QuizRun", optional: true

  validates :pack_id, :token, :status, :expires_at, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :token, uniqueness: true

  scope :active, -> { where(status: %w[pending challenger_done opponent_done]) }
  scope :not_expired, -> { where("expires_at > ?", Time.current) }

  def pending? = status == "pending"
  def challenger_done? = status == "challenger_done"
  def opponent_done? = status == "opponent_done"
  def resolved? = status == "resolved"
  def expired? = expires_at <= Time.current

  def winner_person
    return unless resolved? && challenger_score && opponent_score

    if challenger_score > opponent_score
      challenger_person
    elsif opponent_score > challenger_score
      opponent_person
    end
  end

  def loser_person
    winner = winner_person
    return unless winner

    winner.id == challenger_person_id ? opponent_person : challenger_person
  end
end
