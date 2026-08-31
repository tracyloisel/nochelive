module Scriptures
  class QueryResolver
    Suggestion = Data.define(:label, :path, :study)
    Result = Data.define(:status, :path, :suggestions, :message_key) do
      def exact? = status == :exact
      def invalid? = status == :invalid
    end

    EXTRA_ALIASES = {
      "dc-testament/dc" => [ "dyc", "d y c", "d&c", "d c", "d&a", "d a",
        "doctrine et alliances", "doctrina y convenios", "doctrine and covenants",
        "doutrina e convenios", "doutrina e convênios" ]
    }.freeze

    def self.call(query:, locale: I18n.locale, routes: Rails.application.routes.url_helpers, context: :public)
      new(query:, locale:, routes:, context:).call
    end

    def initialize(query:, locale:, routes:, context:)
      @query = query.to_s
      @locale = Locale.i18n(locale)
      @routes = routes
      @context = context.to_sym == :library ? :library : :public
    end

    def call
      normalized = normalize(@query)
      return result(:invalid, :empty) if normalized.blank?

      match = normalized.match(/\A(.+?)\s+(\d+)(?:\s*:\s*(\d+)(?:\s*-\s*(\d+))?)?\z/)
      return suggestions_for(normalized) unless match

      book_query, chapter, from, to = match.captures
      books = matching_books(book_query)
      return result(:invalid, :unknown) if books.empty?
      return ambiguous(books, chapter) if books.many?

      book = books.first
      chapter = chapter.to_i
      return result(:invalid, :bounds) unless chapter.between?(1, book[:data][:chapters])
      return exact(book, chapter) unless from

      from = from.to_i
      to = (to || from).to_i
      study = "#{book[:study]}/#{chapter}"
      return result(:invalid, :bounds) unless Scriptures::ChapterVerseCounts.valid_range?(study:, from:, to:)

      reference = Scriptures::Reference.from_study(study:, locale: @locale, verse: from)
      path = if library_context?
        @routes.scripture_path(reference.study, cite: passage_citation(reference, to), locale: @locale)
      else
        @routes.scripture_passage_path(**Scriptures::Reference.passage_path_options(reference, @locale, to:))
      end
      Result.new(status: :exact, path:, suggestions: [], message_key: nil)
    end

    private

      def exact(book, chapter)
        reference = Scriptures::Reference.from_study(study: "#{book[:study]}/#{chapter}", locale: @locale, verse: 1)
        path = if library_context?
          @routes.scripture_path(reference.study, cite: reference.citation.delete_suffix(":1"), locale: @locale)
        else
          @routes.scripture_chapter_path(**Scriptures::Reference.chapter_path_options(reference, @locale))
        end
        Result.new(status: :exact, path:, suggestions: [], message_key: nil)
      end

      def suggestions_for(term)
        books = catalog.select { |book| book[:aliases].any? { |name| name.start_with?(term) || name.include?(term) } }.first(6)
        return result(:invalid, :unknown) if books.empty?

        exact_books = books.select { |book| book[:aliases].include?(term) }
        return exact_book(exact_books.first) if library_context? && exact_books.one?

        Result.new(status: :ambiguous, path: nil, suggestions: books.map { |book| suggestion(book) }, message_key: nil)
      end

      def ambiguous(books, chapter)
        Result.new(status: :ambiguous, path: nil,
          suggestions: books.first(6).map { |book| suggestion(book, chapter) }, message_key: nil)
      end

      def suggestion(book, chapter = nil)
        label = [ book[:label], chapter ].compact.join(" ")
        path = if chapter&.to_i&.between?(1, book[:data][:chapters])
          reference = Scriptures::Reference.from_study(study: "#{book[:study]}/#{chapter}", locale: @locale, verse: 1)
          if library_context?
            @routes.scripture_path(reference.study, cite: "#{reference.book_label} #{reference.chapter}", locale: @locale)
          else
            @routes.scripture_chapter_path(**Scriptures::Reference.chapter_path_options(reference, @locale))
          end
        elsif library_context?
          library_book_path(book)
        else
          localized = Scriptures::Reference.books(@locale).find { |item| item.base_study == book[:study] }
          @routes.scripture_book_path(**Scriptures::Reference.book_path_options(localized, @locale))
        end
        Suggestion.new(label:, path:, study: book[:study])
      end

      def matching_books(name)
        catalog.select { |book| book[:aliases].include?(normalize(name)) }
      end

      def catalog
        @catalog ||= Scriptures::Reference::BOOKS.map do |study, data|
          localized = data[:names].fetch(@locale)
          aliases = data[:names].values.flatten + Array(EXTRA_ALIASES[study])
          { study:, data:, label: localized.last, aliases: aliases.map { |name| normalize(name) }.uniq }
        end
      end

      def normalize(value)
        ActiveSupport::Inflector.transliterate(value.to_s.downcase.tr("–—−", "---"))
          .gsub("&", " and ").gsub(/[^a-z0-9:-]+/, " ").squish
          .gsub(/\bd\s+and\s+([ac])\b/, 'd \1')
      end

      def result(status, message)
        Result.new(status:, path: nil, suggestions: [], message_key: "scripture_library.search.errors.#{message}")
      end

      def exact_book(book)
        Result.new(status: :exact, path: library_book_path(book), suggestions: [], message_key: nil)
      end

      def library_book_path(book)
        @routes.scripture_library_path(
          section: "canon", collection: collection_for(book[:study]), book: book[:study],
          locale: @locale, anchor: "selection"
        )
      end

      def collection_for(study)
        return :old_testament if study.start_with?("ot/")
        return :new_testament if study.start_with?("nt/")
        return :book_of_mormon if study.start_with?("bofm/")

        :doctrine_and_covenants
      end

      def passage_citation(reference, to)
        verses = reference.verse == to ? reference.verse.to_s : "#{reference.verse}–#{to}"
        "#{reference.book_label} #{reference.chapter}:#{verses}"
      end

      def library_context?
        @context == :library
      end
  end
end
