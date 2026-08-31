module Hubs
  # Adapts the quiz reading recommendations for the Hub. Keeping this layer out
  # of the partial means the Home never needs to know how a missed quiz answer,
  # a scripture route, artwork, and reading progress fit together.
  class ReadingCards
    Card = Struct.new(
      :study, :cite, :title, :artwork, :status, :progress_percent,
      keyword_init: true
    )

    def self.call(person:, locale: I18n.locale, suggestions: nil)
      new(person:, locale:, suggestions:).call
    end

    # The Hub has two chapter-card sources: quiz recommendations and the
    # editorial reading list for the current Come, Follow Me week. They share
    # one truthful reading-progress vocabulary so a card never calls a brief
    # accidental opening "in progress" in one rail and "to read" in another.
    def self.progress_status(progress)
      return [ :completed, 100 ] if progress&.completed_at.present?
      return [ :in_progress, (progress.progress_ratio.to_f * 100).round ] if progress&.resumable?

      [ :unread, nil ]
    end

    def initialize(person:, locale:, suggestions:)
      @person = person
      @locale = locale.to_s
      @suggestions = suggestions
    end

    def call
      suggestions = Array(@suggestions || Quizzes::ReadingSuggestions.call(person: @person)).uniq(&:study)
      return [] if suggestions.empty?

      progress_by_study = reading_progress_by_study(suggestions)
      suggestions.filter_map do |suggestion|
        build_card(suggestion, progress_by_study[suggestion.study])
      end
    end

    private

      # This one preload is deliberately kept here. A recommendation rail may
      # contain several chapters and must not add one reading-progress query per
      # card as it renders.
      def reading_progress_by_study(suggestions)
        return {} unless @person

        studies = suggestions.filter_map(&:study).uniq
        return {} if studies.empty?

        ScriptureReadingProgress
          .where(person: @person, locale: @locale, reference: studies)
          .index_by(&:reference)
      end

      def build_card(suggestion, progress)
        reference = Scriptures::Reference.from_study(study: suggestion.study, locale: @locale, verse: 1)
        return unless reference

        status, progress_percent = reading_status(progress)
        Card.new(
          study: suggestion.study,
          cite: suggestion.cite,
          title: "#{reference.book_label} #{reference.chapter}",
          artwork: question_artwork(suggestion),
          status:,
          progress_percent:
        )
      rescue QuizDefinition::Error
        nil
      end

      def reading_status(progress)
        self.class.progress_status(progress)
      end

      def question_artwork(suggestion)
        question = QuizDefinition.catalog.find_question(suggestion.pack_id, suggestion.question_id)
        source = question.presentation.fetch("image", "").to_s
        return if source.blank?

        source = source.delete_prefix("/")
        source = "media/#{source}" unless source.start_with?("media/")
        source if Frontend::MediaManifest.fetch_source(source)
      end
  end
end
