class QuizRun < ApplicationRecord
  STATUSES = %w[open finished].freeze

  has_many :quiz_answers, dependent: :destroy

  validates :device_digest, :pack_id, :status, :opened_at, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :position, numericality: { only_integer: true, greater_than: 0 }
  validates :score, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :open_runs, -> { where(status: "open") }
  scope :finished, -> { where(status: "finished") }

  def pack
    QuizDefinition.catalog.find_pack(pack_id)
  end

  def question
    pack.question_at(position)
  end

  def definition
    question
  end

  def current_answer
    quiz_answers.find_by(question_id: question.id)
  end

  def settled?
    current_answer.present?
  end

  def last_question?
    position >= pack.questions.size
  end

  def open?
    status == "open"
  end

  def finished?
    status == "finished"
  end

  def timed?
    return false if settled? || finished?
    question.timed? && ends_at.present?
  end

  def seconds_left
    return 0 unless ends_at

    [ (ends_at - Time.current).ceil, 0 ].max
  end

  def expired?
    timed? && Time.current >= ends_at
  end
end
