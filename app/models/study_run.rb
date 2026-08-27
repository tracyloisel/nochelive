class StudyRun < ApplicationRecord
  STATUSES = %w[open completed].freeze

  belongs_to :person, optional: true
  belongs_to :study_quiz_version
  has_many :study_answers, dependent: :destroy

  validates :device_digest, :status, :opened_at, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :position, numericality: { only_integer: true, in: 1..10 }
  validates :score, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :open, -> { where(status: "open") }
  scope :completed, -> { where(status: "completed") }

  delegate :study_unit, to: :study_quiz_version

  def question
    study_quiz_version.localized_question(position)
  end

  def current_answer
    study_answers.find_by(question_key: question.fetch("key"))
  end

  def settled?
    current_answer.present?
  end

  def completed?
    status == "completed"
  end
end
