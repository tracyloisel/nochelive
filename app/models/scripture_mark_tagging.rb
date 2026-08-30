class ScriptureMarkTagging < ApplicationRecord
  belongs_to :scripture_mark
  belongs_to :scripture_tag

  validates :scripture_tag_id, uniqueness: { scope: :scripture_mark_id }
  validate :same_owner

  private

    def same_owner
      return if scripture_mark.blank? || scripture_tag.blank?
      return if scripture_mark.person_id == scripture_tag.person_id

      errors.add(:scripture_tag, :invalid)
    end
end
