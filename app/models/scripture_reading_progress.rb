class ScriptureReadingProgress < ApplicationRecord
  belongs_to :person

  validates :reference, :locale, :first_opened_at, :last_opened_at, presence: true
  validates :reference, uniqueness: { scope: [ :person_id, :locale ] }
  validates :locale, inclusion: { in: Locale::AVAILABLE }
  validates :last_verse, numericality: { only_integer: true, greater_than: 0 }
  validates :last_offset, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :progress_ratio, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
  validate :known_reference

  def resumable?
    progress_ratio.to_f >= 0.08 && completed_at.blank?
  end

  private

    def known_reference
      errors.add(:reference, :invalid) unless Scriptures::Reference.known_study?(reference)
    end
end
