class ScriptureNotebook < ApplicationRecord
  TITLE_LIMIT = 80
  DESCRIPTION_LIMIT = 500

  belongs_to :person
  has_many :scripture_notebook_entries, dependent: :destroy
  has_many :scripture_marks, through: :scripture_notebook_entries

  validates :title, presence: true, length: { maximum: TITLE_LIMIT }
  validates :description, length: { maximum: DESCRIPTION_LIMIT }, allow_blank: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation do
    self.title = title.to_s.squish
    self.description = description.to_s.strip.presence
  end
end
