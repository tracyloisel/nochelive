class ScriptureNotebookEntry < ApplicationRecord
  belongs_to :scripture_notebook
  belongs_to :scripture_mark

  validates :scripture_mark_id, uniqueness: { scope: :scripture_notebook_id }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :same_owner

  private

    def same_owner
      return if scripture_mark.blank? || scripture_notebook.blank?
      return if scripture_mark.person_id == scripture_notebook.person_id

      errors.add(:scripture_mark, :invalid)
    end
end
