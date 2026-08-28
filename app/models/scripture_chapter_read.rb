class ScriptureChapterRead < ApplicationRecord
  belongs_to :person, optional: true

  validates :reference, :reader_digest, :locale, :read_on, presence: true
end
