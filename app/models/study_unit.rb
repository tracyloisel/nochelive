class StudyUnit < ApplicationRecord
  KINDS = %w[introduction reflection week appendix].freeze

  belongs_to :study_program
  has_many :study_quiz_versions, dependent: :destroy
  has_many :reading_progresses, dependent: :destroy

  validates :slug, :kind, :position, :title, :source_url, :status, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :slug, uniqueness: { scope: :study_program_id }

  scope :weeks, -> { where(kind: "week").order(:starts_on) }
  scope :appendices, -> { where(kind: "appendix").order(:position) }
  scope :resources, -> { where(kind: %w[introduction reflection appendix]).order(:position) }

  def week?
    kind == "week"
  end

  def appendix?
    kind == "appendix"
  end

  def published_quiz
    if study_quiz_versions.loaded?
      study_quiz_versions.select { |version| version.status == "published" }.max_by(&:version)
    else
      study_quiz_versions.where(status: "published").order(version: :desc).first
    end
  end

  def display_title(locale = I18n.locale)
    copy.dig(locale.to_s, "title").presence || title
  end

  def theme(locale = I18n.locale)
    copy.dig(locale.to_s, "theme").presence || copy.dig("fr", "theme").presence || title
  end
end
