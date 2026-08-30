class ScriptureChapterGuide < ApplicationRecord
  STATUSES = %w[draft review published retired].freeze

  validates :reference, :locale, :welcome_title, :summary, :status, :revision, presence: true
  validates :reference, uniqueness: { scope: [ :locale, :revision ] }
  validates :locale, inclusion: { in: Locale::AVAILABLE }
  validates :status, inclusion: { in: STATUSES }
  validates :revision, numericality: { only_integer: true, greater_than: 0 }
  validates :historical_context, :literary_structure, length: { maximum: 1_200 }, allow_blank: true
  validate :known_reference
  validate :published_metadata

  scope :published, -> { where(status: "published").where.not(published_at: nil) }

  private

    def known_reference
      errors.add(:reference, :invalid) unless Scriptures::Reference.known_study?(reference)
    end

    def published_metadata
      return unless status == "published"
      errors.add(:reviewed_by, :blank) if reviewed_by.blank?
      errors.add(:published_at, :blank) if published_at.blank?
      errors.add(:source_citations, :blank) if Array(source_citations).empty?
    end
end
