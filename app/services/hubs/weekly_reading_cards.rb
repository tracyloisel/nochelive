module Hubs
  # Presents the real individual readings published for the current Come,
  # Follow Me week. It deliberately stays separate from ReadingCards: quiz
  # recommendations and the weekly programme have different editorial sources,
  # even though they share the same truthful chapter-progress state.
  class WeeklyReadingCards
    Card = Struct.new(
      :study, :cite, :title, :artwork, :status, :progress_percent,
      :study_unit_id,
      keyword_init: true
    )

    def self.call(person:, week:, quiz:, locale: I18n.locale)
      new(person:, week:, quiz:, locale:).call
    end

    def initialize(person:, week:, quiz:, locale:)
      @person = person
      @week = week
      @quiz = quiz
      @locale = locale.to_s
    end

    def call
      readings = published_readings
      return [] if @week.blank? || readings.empty?

      progress_by_study = reading_progress_by_study(readings)
      cards = readings.filter_map do |reading|
        build_card(reading, progress_by_study[reading.fetch("study")])
      end
      cards
    end

    private

      # A programme can be corrected editorially. Preserve its published
      # sequence, but never render the same chapter twice if two source rows
      # accidentally point to it.
      def published_readings
        Array(@quiz&.readings(@locale)).filter_map do |reading|
          study = reading["study"].to_s
          next if study.blank?

          reading.merge("study" => study)
        end.uniq { |reading| reading.fetch("study") }
      end

      # This remains one preload for the whole weekly rail. The view receives
      # plain cards and therefore cannot introduce a per-chapter query.
      def reading_progress_by_study(readings)
        return {} unless @person

        ScriptureReadingProgress
          .where(person: @person, locale: @locale, reference: readings.map { |reading| reading.fetch("study") })
          .index_by(&:reference)
      end

      def build_card(reading, progress)
        reference = Scriptures::Reference.from_study(study: reading.fetch("study"), locale: @locale, verse: 1)
        return unless reference

        status, progress_percent = Hubs::ReadingCards.progress_status(progress)
        # The chapter title is resolved from its canonical study reference,
        # never copied from editorial copy. The published label is still kept
        # as the reader citation, where an editor may add useful context.
        title = "#{reference.book_label} #{reference.chapter}"
        Card.new(
          study: reading.fetch("study"),
          cite: reading["label"].presence || title,
          title:,
          artwork: artwork,
          status:,
          progress_percent:,
          study_unit_id: @week.id
        )
      end

      # Week artwork is editorial source material, not a synthetic decorative
      # fill. If it has not been approved into the media manifest we show the
      # semantic card surface instead of an invented image.
      def artwork
        return @artwork if defined?(@artwork)

        source = @quiz&.content&.fetch("artwork", "").to_s
        source = source.delete_prefix("/")
        source = "media/#{source}" unless source.blank? || source.start_with?("media/")
        @artwork = source.presence if source.present? && Frontend::MediaManifest.fetch_source(source)
      end
  end
end
