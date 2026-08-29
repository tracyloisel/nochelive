module Scriptures
  class Illustrations
    MAX_PER_CHAPTER = 3
    SAFE_MEDIA_PATH = %r{\A[\w./-]+\z}

    Illustration = Data.define(
      :image, :alt, :caption, :citation, :from_verse, :to_verse, :anchor_verse
    )

    def self.call(chapter:, locale: I18n.locale, questions: nil)
      questions ||= catalog_questions
      new(chapter:, locale:, questions:).call
    end

    def self.verse_ranges(cite, chapter_number)
      normalized = cite.to_s.tr("–—", "-")
      normalized.scan(/(?:\A|[^\d])(\d+):([\d,\-\s]+)/).filter_map do |number, verses|
        next unless number.to_i == chapter_number.to_i

        verses.split(",").filter_map do |part|
          from, to = part.strip.split("-", 2).map(&:to_i)
          to ||= from
          next if from <= 0 || to < from

          (from..to)
        end
      end.flatten
    end

    def self.catalog_questions
      QuizDefinition.catalog.all_questions
    rescue QuizDefinition::Error, Errno::ENOENT
      []
    end

    def initialize(chapter:, locale:, questions:)
      @chapter = chapter
      @locale = locale
      @questions = questions
    end

    def call
      return [] unless @chapter&.study.present? && @chapter.verses.present?

      I18n.with_locale(@locale) do
        candidates = @questions.filter_map { |question| build(question) }
        choose(candidates)
      end
    end

    private

      def build(question)
        return unless question.scripture.study == @chapter.study

        image = question.presentation["image"].to_s
        return unless media_available?(image)

        ranges = self.class.verse_ranges(question.scripture.cite, chapter_number)
        covered = @chapter.verses.map(&:number).select do |number|
          ranges.any? { |range| range.cover?(number) }
        end
        return if covered.empty?

        from = covered.min
        to = covered.max
        Illustration.new(
          image:,
          alt: question.copy(:question),
          caption: question.copy(:answer),
          citation: citation(from, to),
          from_verse: from,
          to_verse: to,
          anchor_verse: to
        )
      end

      def media_available?(image)
        image.present? && image.match?(SAFE_MEDIA_PATH) && !image.split("/").include?("..") &&
          Frontend::MediaManifest.fetch_source("media/#{image}").present?
      end

      def chapter_number
        @chapter.study.to_s.split("/").last.to_i
      end

      def citation(from, to)
        verses = from == to ? from.to_s : "#{from}–#{to}"
        "#{@chapter.title}:#{verses}"
      end

      def choose(candidates)
        representatives = candidates
          .group_by(&:anchor_verse)
          .sort_by(&:first)
          .map { |_anchor, group| group.max_by { |item| item.to_verse - item.from_verse } }
        return representatives if representatives.size <= MAX_PER_CHAPTER

        last = representatives.size - 1
        [ 0, (last / 2.0).round, last ].uniq.map { |index| representatives[index] }
      end
  end
end
