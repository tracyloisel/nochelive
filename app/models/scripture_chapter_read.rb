class ScriptureChapterRead < ApplicationRecord
  belongs_to :person, optional: true
  belongs_to :ward, optional: true

  validates :reference, :reader_digest, :locale, :read_on, presence: true
end
