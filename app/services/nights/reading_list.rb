module Nights
  class ReadingList
    Entry = Data.define(:study, :cite)

    def self.call(night:)
      night.quiz_packs.flat_map(&:questions)
        .filter_map { |question| question.scripture && Entry.new(question.scripture.study, question.scripture.cite) }
        .uniq
    end
  end
end
