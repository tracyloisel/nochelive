module Nights
  class ReadingList
    Entry = Data.define(:study, :cite)

    def self.call(night:)
      night.quiz_packs.flat_map do |pack|
        if pack.readings.present?
          pack.readings.map { |reading| Entry.new(reading.fetch("study"), reading.fetch("cite")) }
        else
          pack.questions.filter_map { |question| question.scripture && Entry.new(question.scripture.study, question.scripture.cite) }
        end
      end
        .uniq(&:study)
    end
  end
end
