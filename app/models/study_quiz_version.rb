class StudyQuizVersion < ApplicationRecord
  STATUSES = %w[draft needs_review published retired].freeze

  belongs_to :study_unit
  has_many :study_runs, dependent: :restrict_with_exception

  validates :version, :status, :editorial_locale, :content, :content_digest, presence: true
  validates :version, uniqueness: { scope: :study_unit_id }
  validates :status, inclusion: { in: STATUSES }
  validate :ten_questions

  def questions
    Array(content["questions"])
  end

  def readings(locale = I18n.locale)
    Array(content["readings"]).filter_map do |reading|
      next unless reading["study"].present?

      reading.merge("label" => reading.dig("labels", locale.to_s) || reading.dig("labels", "fr"))
    end
  end

  def reading_for(question, locale = I18n.locale)
    chapter = question["scripture_ref"].to_s[/\d+/]
    readings(locale).find { |reading| reading["study"].to_s.end_with?("/#{chapter}") }
  end

  def self.known_scripture_study?(study)
    where(status: "published").pluck(:content).any? do |payload|
      Array(payload["readings"]).any? { |reading| reading["study"] == study }
    end
  end

  def question_at(position)
    questions.fetch(position.to_i - 1)
  end

  def localized_question(position, locale = I18n.locale)
    question = question_at(position)
    localized = question.dig("locales", locale.to_s) || question.dig("locales", "fr") || {}
    question.merge(localized)
  end

  private

    def ten_questions
      errors.add(:content, "must contain 10 questions") unless questions.size == 10
    end
end
