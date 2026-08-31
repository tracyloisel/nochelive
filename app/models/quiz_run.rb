class QuizRun < ApplicationRecord
  STATUSES = %w[open finished expired].freeze

  belongs_to :person, optional: true
  belongs_to :game_session, optional: true
  belongs_to :player, optional: true
  belongs_to :team, optional: true
  has_many :quiz_answers, dependent: :destroy

  validates :device_digest, :pack_id, :status, :opened_at, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :position, numericality: { only_integer: true, greater_than: 0 }
  validates :score, :base_score, :fire_count, :fire_bonus,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :live_sequence_position, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :live_context_is_complete

  scope :open_runs, -> { where(status: "open") }
  scope :finished, -> { where(status: "finished") }
  scope :live, -> { where.not(game_session_id: nil) }
  scope :street, -> { where(game_session_id: nil) }

  def pack = QuizDefinition.catalog.find_pack(pack_id)
  def question = pack.question_at(position)
  def definition = question
  def current_answer = quiz_answers.find_by(question_id: question.id)
  def settled? = current_answer.present?
  def last_question? = position >= pack.questions.size
  def open? = status == "open"
  def finished? = status == "finished"
  def expired_run? = status == "expired"
  def live? = game_session_id.present?
  def street? = !live?

  def timed?
    return false if settled? || !open?
    question.timed? && ends_at.present?
  end

  def seconds_left = ends_at ? [ (ends_at - Time.current).ceil, 0 ].max : 0
  def expired? = timed? && Time.current >= ends_at

  private

    def live_context_is_complete
      values = [ game_session_id, player_id, team_id, live_sequence_position ]
      return if values.all?(&:blank?) || values.all?(&:present?)

      errors.add(:base, "live quiz runs require a night, player, team, and sequence position")
    end
end
