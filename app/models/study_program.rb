class StudyProgram < ApplicationRecord
  STATUSES = %w[draft published archived].freeze

  has_many :study_units, -> { order(:position) }, dependent: :destroy

  validates :slug, :title, :year, :canon, :locale, :status, :source_url, presence: true
  validates :slug, uniqueness: true
  validates :year, numericality: { only_integer: true, greater_than: 2000 }
  validates :status, inclusion: { in: STATUSES }

  def current_week(on: Date.current)
    study_units.weeks.find_by("starts_on <= ? AND ends_on >= ?", on, on)
  end
end
