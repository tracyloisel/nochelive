class ScriptureMarkLink < ApplicationRecord
  belongs_to :scripture_mark

  validates :target_reference, :target_locale, presence: true
  validates :target_locale, inclusion: { in: Locale::AVAILABLE }
  validates :target_text, length: { maximum: ScriptureMark::SELECTED_TEXT_LIMIT }, allow_blank: true
  validate :known_target

  private

    def known_target
      errors.add(:target_reference, :invalid) unless Scriptures::Reference.known_study?(target_reference)
    end
end
