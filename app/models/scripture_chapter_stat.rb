class ScriptureChapterStat < ApplicationRecord
  validates :reference, presence: true
  validates :reads_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.count_for(reference)
    find_by(reference:)&.reads_count.to_i
  end
end
