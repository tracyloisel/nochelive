module Scriptures
  class QueryResolver
    Suggestion = Data.define(:label, :path, :study)
    Result = Data.define(:status, :path, :suggestions, :message_key) do
      def exact? = status == :exact
    end

    EXTRA_ALIASES = {
      "dc-testament/dc" => [ "dyc", "d y c", "d&c", "d c", "dc", "d&a", "d a",
        "doctrine et alliances", "doctrina y convenios", "doctrine and covenants",
        "doutrina e convenios", "doutrina e convênios" ]
    }.freeze

    BOOK_ABBREVIATIONS = {
      "ot/gen" => %w[gen gn ge],
      "ot/ex" => %w[ex exo ex],
      "ot/lev" => %w[lev lv le],
      "ot/num" => %w[num nb nm],
      "ot/deut" => %w[deut dt de deutero],
      "ot/josh" => %w[josh jos jsh],
      "ot/judg" => %w[judg jdg jz jue],
      "ot/ruth" => %w[ruth rut rt],
      "ot/1-sam" => %w[1sam 1sm 1s],
      "ot/2-sam" => %w[2sam 2sm 2s],
      "ot/1-kgs" => %w[1kgs 1k 1ki 1reyes],
      "ot/2-kgs" => %w[2kgs 2k 2ki 2reyes],
      "ot/1-chr" => %w[1chr 1ch 1cronicas],
      "ot/2-chr" => %w[2chr 2ch 2cronicas],
      "ot/ezra" => %w[ezr esd],
      "ot/neh" => %w[neh ne],
      "ot/esth" => %w[esth est],
      "ot/job" => %w[job jb],
      "ot/ps" => %w[ps psa pss slm sal sl],
      "ot/prov" => %w[prov pr pv pr],
      "ot/eccl" => %w[eccl ecc ec qo],
      "ot/song" => %w[song sos cnt cant],
      "ot/isa" => %w[isa is es],
      "ot/jer" => %w[jer jr jeremias],
      "ot/lam" => %w[lam lm],
      "ot/ezek" => %w[ezek ezekiel eze ez],
      "ot/dan" => %w[dan dn],
      "ot/hosea" => %w[hosea hos os osee],
      "ot/joel" => %w[joel jl],
      "ot/amos" => %w[amos am],
      "ot/obad" => %w[obad ob abd abdias],
      "ot/jonah" => %w[jonah jon jnas],
      "ot/micah" => %w[micah mic mi miqueas],
      "ot/nahum" => %w[nahum nah na],
      "ot/hab" => %w[hab hb habacuc],
      "ot/zeph" => %w[zeph zeph zep sof sofonias],
      "ot/hag" => %w[hag hg hageo aggeo],
      "ot/zech" => %w[zech zec zac zacharie],
      "ot/mal" => %w[mal ml malaquias],
      "nt/matt" => %w[matt mat mt mateo matthieu],
      "nt/mark" => %w[mark mk mr marcos],
      "nt/luke" => %w[luke lk luc],
      "nt/john" => %w[john jn juan jean],
      "nt/acts" => %w[acts ac actes hechos at],
      "nt/rom" => %w[rom rm ro],
      "nt/1-cor" => %w[1cor 1co 1c],
      "nt/2-cor" => %w[2cor 2co 2c],
      "nt/gal" => %w[gal ga],
      "nt/eph" => %w[eph efe],
      "nt/philip" => %w[philip phil php fil filipenses],
      "nt/col" => %w[col cl],
      "nt/1-thes" => %w[1thes 1th 1ts],
      "nt/2-thes" => %w[2thes 2th 2ts],
      "nt/1-tim" => %w[1tim 1ti 1tm],
      "nt/2-tim" => %w[2tim 2ti 2tm],
      "nt/titus" => %w[titus tit],
      "nt/philem" => %w[philem phm filemon philémon],
      "nt/heb" => %w[heb he],
      "nt/james" => %w[james jas stg santiago tiago],
      "nt/1-pet" => %w[1pet 1pe 1p 1pedro],
      "nt/2-pet" => %w[2pet 2pe 2p 2pedro],
      "nt/1-jn" => %w[1jn 1john 1j 1juan 1jean 1joao],
      "nt/2-jn" => %w[2jn 2john 2j 2juan 2jean 2joao],
      "nt/3-jn" => %w[3jn 3john 3j 3juan 3jean 3joao],
      "nt/jude" => %w[jude jud],
      "nt/rev" => %w[rev apoc ap rev apocalypse],
      "bofm/1-ne" => %w[1ne 1nephi 1n 1nefi],
      "bofm/2-ne" => %w[2ne 2nephi 2n 2nefi],
      "bofm/jacob" => %w[jacob jac],
      "bofm/enos" => %w[enos en],
      "bofm/jarom" => %w[jarom jar],
      "bofm/omni" => %w[omni om],
      "bofm/w-of-m" => %w[wofm wm palabras paroles],
      "bofm/mosiah" => %w[mosiah mos],
      "bofm/alma" => %w[alma al],
      "bofm/hel" => %w[hel helaman],
      "bofm/3-ne" => %w[3ne 3nephi 3n 3nefi],
      "bofm/4-ne" => %w[4ne 4nephi 4n 4nefi],
      "bofm/morm" => %w[morm mormon],
      "bofm/ether" => %w[ether eth],
      "bofm/moro" => %w[moro moroni]
    }.freeze

    def self.call(query:, locale: I18n.locale, routes: Rails.application.routes.url_helpers)
      new(query:, locale:, routes:).call
    end

    def initialize(query:, locale:, routes:)
      @query = query.to_s
      @locale = Locale.i18n(locale)
      @routes = routes
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
      return result(:invalid, :bounds) unless from.between?(1, 176) && to.between?(from, 176)

      reference = Scriptures::Reference.from_study(study: "#{book[:study]}/#{chapter}", locale: @locale, verse: from)
      path = @routes.scripture_passage_path(**Scriptures::Reference.passage_path_options(reference, @locale, to:))
      Result.new(status: :exact, path:, suggestions: [], message_key: nil)
    end

    private

      def exact(book, chapter)
        reference = Scriptures::Reference.from_study(study: "#{book[:study]}/#{chapter}", locale: @locale, verse: 1)
        path = @routes.scripture_chapter_path(**Scriptures::Reference.chapter_path_options(reference, @locale))
        Result.new(status: :exact, path:, suggestions: [], message_key: nil)
      end

      def suggestions_for(term)
        books = catalog.select { |book| book[:aliases].any? { |name| name.start_with?(term) || name.include?(term) } }.first(6)
        return result(:invalid, :unknown) if books.empty?

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
          @routes.scripture_chapter_path(**Scriptures::Reference.chapter_path_options(reference, @locale))
        else
          localized = Scriptures::Reference.books(@locale).find { |item| item.base_study == book[:study] }
          @routes.scripture_book_path(**Scriptures::Reference.book_path_options(localized, @locale))
        end
        Suggestion.new(label:, path:, study: book[:study])
      end

      def matching_books(name)
        normalized_name = normalize(name)
        catalog.select { |book| book[:aliases].include?(normalized_name) }
      end

      def catalog
        @catalog ||= Scriptures::Reference::BOOKS.map do |study, data|
          localized = data[:names].fetch(@locale)
          aliases = data[:names].values.flatten + Array(EXTRA_ALIASES[study]) + Array(BOOK_ABBREVIATIONS[study])
          { study:, data:, label: localized.last, aliases: aliases.map { |name| normalize(name) }.uniq }
        end
      end

      def normalize(value)
        ActiveSupport::Inflector.transliterate(value.to_s.downcase.tr("–—−", "---"))
          .gsub("&", " and ").gsub(/[^a-z0-9:-]+/, " ").squish
          .gsub(/\bd\s+and\s+([ac])\b/, 'd \1')
          .gsub(/\b([1-4])\s+(ne|nephi|nefi|sam|samuel|kgs|kings|reyes|reis|chr|chronicles|cronicas|chroniques|cor|corinthians|corintios|coríntios|thes|thessalonians|tesalonicenses|tessalonicenses|tim|timothy|timoteo|timóteo|pe|pet|peter|pedro|jn|john|juan|jean|joao)\b/, '\1\2')
      end

      def result(status, message)
        Result.new(status:, path: nil, suggestions: [], message_key: "scripture_library.search.errors.#{message}")
      end
  end
end
