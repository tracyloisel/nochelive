module ChurchVideos
  class ScriptureCandidates
    Candidate = Data.define(
      :id, :title, :description, :published_at, :duration_seconds, :channel_id, :score
    )
    Result = Data.define(:reference, :locale, :query, :channel, :candidates, :error) do
      def available? = error.nil?
    end

    def self.call(reference:, locale:, themes: [], limit: 12, **catalog_options)
      new(reference:, locale:, themes:, limit:, catalog_options:).call
    end

    def initialize(reference:, locale:, themes:, limit:, catalog_options:)
      @reference = reference.to_s
      @locale = Locale.cast(locale)
      @themes = Array(themes).map { |theme| theme.to_s.squish }.compact_blank.first(4)
      @limit = limit.to_i.clamp(1, 24)
      @catalog_options = catalog_options
    end

    def call
      return failure(:invalid_reference) unless Scriptures::Reference.known_study?(@reference)

      catalogs = candidate_queries.filter_map do |candidate_query|
        result = Catalog.call(locale: @locale, query: candidate_query, **@catalog_options)
        next unless result.available?
        unless result.channel && Catalog.official_channel_id?(locale: @locale, channel_id: result.channel.id)
          return failure(:untrusted_channel)
        end
        result
      end
      return failure(:unavailable) if catalogs.empty?

      channel = catalogs.first.channel
      videos = catalogs.flat_map(&:videos).uniq(&:id)
      candidates = videos.map do |video|
        Candidate.new(
          id: video.id,
          title: video.title,
          description: video.description,
          published_at: video.published_at,
          duration_seconds: video.duration_seconds,
          channel_id: channel.id,
          score: relevance_score(video)
        )
      end.sort_by { |candidate| [ -candidate.score, candidate.title.to_s ] }.first(@limit)

      Result.new(reference: @reference, locale: @locale, query:, channel:, candidates:, error: nil)
    end

    private

      def query
        @query ||= candidate_queries.join(" → ")
      end

      def candidate_queries
        @candidate_queries ||= begin
          chapter = Scriptures::Reference.from_study(study: @reference, locale: @locale.to_sym, verse: 1)
          citation = [ chapter&.book_label, chapter&.chapter ].compact.join(" ")
          [ [ citation, *@themes ].join(" "), citation, @themes.join(" "), chapter&.book_label ]
            .map { |value| value.to_s.squish.first(Catalog::MAX_QUERY_LENGTH) }
            .compact_blank
            .uniq
        end
      end

      def relevance_score(video)
        haystack = ActiveSupport::Inflector.transliterate("#{video.title} #{video.description}").downcase
        query_tokens.sum do |token|
          title = ActiveSupport::Inflector.transliterate(video.title.to_s).downcase
          title.include?(token) ? 3 : (haystack.include?(token) ? 1 : 0)
        end
      end

      def query_tokens
        @query_tokens ||= ActiveSupport::Inflector.transliterate(candidate_queries.join(" ")).downcase.scan(/[a-z0-9]{2,}/).uniq
      end

      def failure(error)
        Result.new(reference: @reference, locale: @locale, query: query, channel: nil, candidates: [], error:)
      end
  end
end
