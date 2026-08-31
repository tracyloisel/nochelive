module Nights
  class ReadingList
    Entry = Data.define(:study, :cite)

    def self.call(night:, locale: I18n.locale)
      night.quiz_packs.flat_map(&:questions)
        .filter_map do |question|
          scripture = question.scripture
          scripture && Entry.new(scripture.study, localized_cite(scripture, locale))
        end
        .uniq(&:study)
    end

    def self.localized_cite(scripture, locale)
      verses = Scriptures::Read.focus_verses(scripture.cite)
      return scripture.cite if verses.empty?

      reference = Scriptures::Reference.from_study(study: scripture.study, locale:, verse: verses.first)
      return scripture.cite unless reference

      ending = verses.last
      range = verses.first == ending ? ending.to_s : "#{verses.first}–#{ending}"
      "#{reference.book_label} #{reference.chapter}:#{range}"
    end
    private_class_method :localized_cite
  end
end
