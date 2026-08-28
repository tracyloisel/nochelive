module Scriptures
  class Reference
    LOCALES = { "es" => :es, "fr" => :fr, "en" => :en, "pt-br" => :"pt-BR" }.freeze
    SECTIONS = {
      bible: { es: "biblia", fr: "bible", en: "bible", "pt-BR": "biblia" },
      book_of_mormon: { es: "libro-de-mormon", fr: "livre-de-mormon", en: "book-of-mormon", "pt-BR": "livro-de-mormon" },
      doctrine_and_covenants: { es: "doctrina-y-convenios", fr: "doctrine-et-alliances", en: "doctrine-and-covenants", "pt-BR": "doutrina-e-convenios" }
    }.freeze

    def self.book(chapters, corpus: :bible, **names)
      { chapters:, corpus:, names: names.transform_keys(&:to_sym) }.freeze
    end
    private_class_method :book

    BOOKS = {
      "ot/gen" => book(50, es: %w[genesis Génesis], fr: %w[genese Genèse], en: %w[genesis Genesis], "pt-BR": %w[genesis Gênesis]),
      "ot/ex" => book(40, es: %w[exodo Éxodo], fr: %w[exode Exode], en: %w[exodus Exodus], "pt-BR": %w[exodo Êxodo]),
      "ot/lev" => book(27, es: %w[levitico Levítico], fr: %w[levitique Lévitique], en: %w[leviticus Leviticus], "pt-BR": %w[levitico Levítico]),
      "ot/num" => book(36, es: %w[numeros Números], fr: %w[nombres Nombres], en: %w[numbers Numbers], "pt-BR": %w[numeros Números]),
      "ot/deut" => book(34, es: %w[deuteronomio Deuteronomio], fr: %w[deuteronome Deutéronome], en: %w[deuteronomy Deuteronomy], "pt-BR": %w[deuteronomio Deuteronômio]),
      "ot/josh" => book(24, es: %w[josue Josué], fr: %w[josue Josué], en: %w[joshua Joshua], "pt-BR": %w[josue Josué]),
      "ot/judg" => book(21, es: %w[jueces Jueces], fr: %w[juges Juges], en: %w[judges Judges], "pt-BR": %w[juizes Juízes]),
      "ot/ruth" => book(4, es: %w[rut Rut], fr: %w[ruth Ruth], en: %w[ruth Ruth], "pt-BR": %w[rute Rute]),
      "ot/1-sam" => book(31, es: [ "1-samuel", "1 Samuel" ], fr: [ "1-samuel", "1 Samuel" ], en: [ "1-samuel", "1 Samuel" ], "pt-BR": [ "1-samuel", "1 Samuel" ]),
      "ot/2-sam" => book(24, es: [ "2-samuel", "2 Samuel" ], fr: [ "2-samuel", "2 Samuel" ], en: [ "2-samuel", "2 Samuel" ], "pt-BR": [ "2-samuel", "2 Samuel" ]),
      "ot/1-kgs" => book(22, es: [ "1-reyes", "1 Reyes" ], fr: [ "1-rois", "1 Rois" ], en: [ "1-kings", "1 Kings" ], "pt-BR": [ "1-reis", "1 Reis" ]),
      "ot/2-kgs" => book(25, es: [ "2-reyes", "2 Reyes" ], fr: [ "2-rois", "2 Rois" ], en: [ "2-kings", "2 Kings" ], "pt-BR": [ "2-reis", "2 Reis" ]),
      "ot/1-chr" => book(29, es: [ "1-cronicas", "1 Crónicas" ], fr: [ "1-chroniques", "1 Chroniques" ], en: [ "1-chronicles", "1 Chronicles" ], "pt-BR": [ "1-cronicas", "1 Crônicas" ]),
      "ot/2-chr" => book(36, es: [ "2-cronicas", "2 Crónicas" ], fr: [ "2-chroniques", "2 Chroniques" ], en: [ "2-chronicles", "2 Chronicles" ], "pt-BR": [ "2-cronicas", "2 Crônicas" ]),
      "ot/ezra" => book(10, es: %w[esdras Esdras], fr: %w[esdras Esdras], en: %w[ezra Ezra], "pt-BR": %w[esdras Esdras]),
      "ot/neh" => book(13, es: %w[nehemias Nehemías], fr: %w[nehemie Néhémie], en: %w[nehemiah Nehemiah], "pt-BR": %w[neemias Neemias]),
      "ot/esth" => book(10, es: %w[ester Ester], fr: %w[esther Esther], en: %w[esther Esther], "pt-BR": %w[ester Ester]),
      "ot/job" => book(42, es: %w[job Job], fr: %w[job Job], en: %w[job Job], "pt-BR": %w[jo Jó]),
      "ot/ps" => book(150, es: %w[salmos Salmos], fr: %w[psaumes Psaumes], en: %w[psalms Psalms], "pt-BR": %w[salmos Salmos]),
      "ot/prov" => book(31, es: %w[proverbios Proverbios], fr: %w[proverbes Proverbes], en: %w[proverbs Proverbs], "pt-BR": %w[proverbios Provérbios]),
      "ot/eccl" => book(12, es: %w[eclesiastes Eclesiastés], fr: %w[ecclesiaste Ecclésiaste], en: %w[ecclesiastes Ecclesiastes], "pt-BR": %w[eclesiastes Eclesiastes]),
      "ot/song" => book(8, es: [ "cantar-de-los-cantares", "Cantar de los Cantares" ], fr: [ "cantique-des-cantiques", "Cantique des Cantiques" ], en: [ "song-of-solomon", "Song of Solomon" ], "pt-BR": [ "canticos", "Cânticos" ]),
      "ot/isa" => book(66, es: %w[isaias Isaías], fr: %w[esaie Ésaïe], en: %w[isaiah Isaiah], "pt-BR": %w[isaias Isaías]),
      "ot/jer" => book(52, es: %w[jeremias Jeremías], fr: %w[jeremie Jérémie], en: %w[jeremiah Jeremiah], "pt-BR": %w[jeremias Jeremias]),
      "ot/lam" => book(5, es: %w[lamentaciones Lamentaciones], fr: %w[lamentations Lamentations], en: %w[lamentations Lamentations], "pt-BR": %w[lamentacoes Lamentações]),
      "ot/ezek" => book(48, es: %w[ezequiel Ezequiel], fr: %w[ezechiel Ézéchiel], en: %w[ezekiel Ezekiel], "pt-BR": %w[ezequiel Ezequiel]),
      "ot/dan" => book(12, es: %w[daniel Daniel], fr: %w[daniel Daniel], en: %w[daniel Daniel], "pt-BR": %w[daniel Daniel]),
      "ot/hosea" => book(14, es: %w[oseas Oseas], fr: %w[osee Osée], en: %w[hosea Hosea], "pt-BR": %w[oseias Oseias]),
      "ot/joel" => book(3, es: %w[joel Joel], fr: %w[joel Joël], en: %w[joel Joel], "pt-BR": %w[joel Joel]),
      "ot/amos" => book(9, es: %w[amos Amós], fr: %w[amos Amos], en: %w[amos Amos], "pt-BR": %w[amos Amós]),
      "ot/obad" => book(1, es: %w[abdias Abdías], fr: %w[abdias Abdias], en: %w[obadiah Obadiah], "pt-BR": %w[obadias Obadias]),
      "ot/jonah" => book(4, es: %w[jonas Jonás], fr: %w[jonas Jonas], en: %w[jonah Jonah], "pt-BR": %w[jonas Jonas]),
      "ot/micah" => book(7, es: %w[miqueas Miqueas], fr: %w[michee Michée], en: %w[micah Micah], "pt-BR": %w[miqueias Miqueias]),
      "ot/nahum" => book(3, es: %w[nahum Nahúm], fr: %w[nahum Nahum], en: %w[nahum Nahum], "pt-BR": %w[naum Naum]),
      "ot/hab" => book(3, es: %w[habacuc Habacuc], fr: %w[habacuc Habacuc], en: %w[habakkuk Habakkuk], "pt-BR": %w[habacuque Habacuque]),
      "ot/zeph" => book(3, es: %w[sofonias Sofonías], fr: %w[sophonie Sophonie], en: %w[zephaniah Zephaniah], "pt-BR": %w[sofonias Sofonias]),
      "ot/hag" => book(2, es: %w[hageo Hageo], fr: %w[aggee Aggée], en: %w[haggai Haggai], "pt-BR": %w[ageu Ageu]),
      "ot/zech" => book(14, es: %w[zacarias Zacarías], fr: %w[zacharie Zacharie], en: %w[zechariah Zechariah], "pt-BR": %w[zacarias Zacarias]),
      "ot/mal" => book(4, es: %w[malaquias Malaquías], fr: %w[malachie Malachie], en: %w[malachi Malachi], "pt-BR": %w[malaquias Malaquias]),
      "nt/matt" => book(28, es: %w[mateo Mateo], fr: %w[matthieu Matthieu], en: %w[matthew Matthew], "pt-BR": %w[mateus Mateus]),
      "nt/mark" => book(16, es: %w[marcos Marcos], fr: %w[marc Marc], en: %w[mark Mark], "pt-BR": %w[marcos Marcos]),
      "nt/luke" => book(24, es: %w[lucas Lucas], fr: %w[luc Luc], en: %w[luke Luke], "pt-BR": %w[lucas Lucas]),
      "nt/john" => book(21, es: %w[juan Juan], fr: %w[jean Jean], en: %w[john John], "pt-BR": %w[joao João]),
      "nt/acts" => book(28, es: %w[hechos Hechos], fr: %w[actes Actes], en: %w[acts Acts], "pt-BR": %w[atos Atos]),
      "nt/rom" => book(16, es: %w[romanos Romanos], fr: %w[romains Romains], en: %w[romans Romans], "pt-BR": %w[romanos Romanos]),
      "nt/1-cor" => book(16, es: [ "1-corintios", "1 Corintios" ], fr: [ "1-corinthiens", "1 Corinthiens" ], en: [ "1-corinthians", "1 Corinthians" ], "pt-BR": [ "1-corintios", "1 Coríntios" ]),
      "nt/2-cor" => book(13, es: [ "2-corintios", "2 Corintios" ], fr: [ "2-corinthiens", "2 Corinthiens" ], en: [ "2-corinthians", "2 Corinthians" ], "pt-BR": [ "2-corintios", "2 Coríntios" ]),
      "nt/gal" => book(6, es: %w[galatas Gálatas], fr: %w[galates Galates], en: %w[galatians Galatians], "pt-BR": %w[galatas Gálatas]),
      "nt/eph" => book(6, es: %w[efesios Efesios], fr: %w[ephesiens Éphésiens], en: %w[ephesians Ephesians], "pt-BR": %w[efesios Efésios]),
      "nt/philip" => book(4, es: %w[filipenses Filipenses], fr: %w[philippiens Philippiens], en: %w[philippians Philippians], "pt-BR": %w[filipenses Filipenses]),
      "nt/col" => book(4, es: %w[colosenses Colosenses], fr: %w[colossiens Colossiens], en: %w[colossians Colossians], "pt-BR": %w[colossenses Colossenses]),
      "nt/1-thes" => book(5, es: [ "1-tesalonicenses", "1 Tesalonicenses" ], fr: [ "1-thessaloniciens", "1 Thessaloniciens" ], en: [ "1-thessalonians", "1 Thessalonians" ], "pt-BR": [ "1-tessalonicenses", "1 Tessalonicenses" ]),
      "nt/2-thes" => book(3, es: [ "2-tesalonicenses", "2 Tesalonicenses" ], fr: [ "2-thessaloniciens", "2 Thessaloniciens" ], en: [ "2-thessalonians", "2 Thessalonians" ], "pt-BR": [ "2-tessalonicenses", "2 Tessalonicenses" ]),
      "nt/1-tim" => book(6, es: [ "1-timoteo", "1 Timoteo" ], fr: [ "1-timothee", "1 Timothée" ], en: [ "1-timothy", "1 Timothy" ], "pt-BR": [ "1-timoteo", "1 Timóteo" ]),
      "nt/2-tim" => book(4, es: [ "2-timoteo", "2 Timoteo" ], fr: [ "2-timothee", "2 Timothée" ], en: [ "2-timothy", "2 Timothy" ], "pt-BR": [ "2-timoteo", "2 Timóteo" ]),
      "nt/titus" => book(3, es: %w[tito Tito], fr: %w[tite Tite], en: %w[titus Titus], "pt-BR": %w[tito Tito]),
      "nt/philem" => book(1, es: %w[filemon Filemón], fr: %w[philemon Philémon], en: %w[philemon Philemon], "pt-BR": %w[filemom Filemom]),
      "nt/heb" => book(13, es: %w[hebreos Hebreos], fr: %w[hebreux Hébreux], en: %w[hebrews Hebrews], "pt-BR": %w[hebreus Hebreus]),
      "nt/james" => book(5, es: %w[santiago Santiago], fr: %w[jacques Jacques], en: %w[james James], "pt-BR": %w[tiago Tiago]),
      "nt/1-pet" => book(5, es: [ "1-pedro", "1 Pedro" ], fr: [ "1-pierre", "1 Pierre" ], en: [ "1-peter", "1 Peter" ], "pt-BR": [ "1-pedro", "1 Pedro" ]),
      "nt/2-pet" => book(3, es: [ "2-pedro", "2 Pedro" ], fr: [ "2-pierre", "2 Pierre" ], en: [ "2-peter", "2 Peter" ], "pt-BR": [ "2-pedro", "2 Pedro" ]),
      "nt/1-jn" => book(5, es: [ "1-juan", "1 Juan" ], fr: [ "1-jean", "1 Jean" ], en: [ "1-john", "1 John" ], "pt-BR": [ "1-joao", "1 João" ]),
      "nt/2-jn" => book(1, es: [ "2-juan", "2 Juan" ], fr: [ "2-jean", "2 Jean" ], en: [ "2-john", "2 John" ], "pt-BR": [ "2-joao", "2 João" ]),
      "nt/3-jn" => book(1, es: [ "3-juan", "3 Juan" ], fr: [ "3-jean", "3 Jean" ], en: [ "3-john", "3 John" ], "pt-BR": [ "3-joao", "3 João" ]),
      "nt/jude" => book(1, es: %w[judas Judas], fr: %w[jude Jude], en: %w[jude Jude], "pt-BR": %w[judas Judas]),
      "nt/rev" => book(22, es: %w[apocalipsis Apocalipsis], fr: %w[apocalypse Apocalypse], en: %w[revelation Revelation], "pt-BR": %w[apocalipse Apocalipse]),
      "bofm/1-ne" => book(22, corpus: :book_of_mormon, es: [ "1-nefi", "1 Nefi" ], fr: [ "1-nephi", "1 Néphi" ], en: [ "1-nephi", "1 Nephi" ], "pt-BR": [ "1-nefi", "1 Néfi" ]),
      "bofm/2-ne" => book(33, corpus: :book_of_mormon, es: [ "2-nefi", "2 Nefi" ], fr: [ "2-nephi", "2 Néphi" ], en: [ "2-nephi", "2 Nephi" ], "pt-BR": [ "2-nefi", "2 Néfi" ]),
      "bofm/jacob" => book(7, corpus: :book_of_mormon, es: %w[jacob Jacob], fr: %w[jacob Jacob], en: %w[jacob Jacob], "pt-BR": %w[jaco Jacó]),
      "bofm/enos" => book(1, corpus: :book_of_mormon, es: %w[enos Enós], fr: %w[enos Énos], en: %w[enos Enos], "pt-BR": %w[enos Enos]),
      "bofm/jarom" => book(1, corpus: :book_of_mormon, es: %w[jarom Jarom], fr: %w[jarom Jarom], en: %w[jarom Jarom], "pt-BR": %w[jarom Jarom]),
      "bofm/omni" => book(1, corpus: :book_of_mormon, es: %w[omni Omni], fr: %w[omni Omni], en: %w[omni Omni], "pt-BR": %w[omni Ômni]),
      "bofm/w-of-m" => book(1, corpus: :book_of_mormon, es: [ "palabras-de-mormon", "Palabras de Mormón" ], fr: [ "paroles-de-mormon", "Paroles de Mormon" ], en: [ "words-of-mormon", "Words of Mormon" ], "pt-BR": [ "palavras-de-mormon", "Palavras de Mórmon" ]),
      "bofm/mosiah" => book(29, corpus: :book_of_mormon, es: %w[mosiah Mosíah], fr: %w[mosiah Mosiah], en: %w[mosiah Mosiah], "pt-BR": %w[mosias Mosias]),
      "bofm/alma" => book(63, corpus: :book_of_mormon, es: %w[alma Alma], fr: %w[alma Alma], en: %w[alma Alma], "pt-BR": %w[alma Alma]),
      "bofm/hel" => book(16, corpus: :book_of_mormon, es: %w[helaman Helamán], fr: %w[helaman Hélaman], en: %w[helaman Helaman], "pt-BR": %w[hela Helamã]),
      "bofm/3-ne" => book(30, corpus: :book_of_mormon, es: [ "3-nefi", "3 Nefi" ], fr: [ "3-nephi", "3 Néphi" ], en: [ "3-nephi", "3 Nephi" ], "pt-BR": [ "3-nefi", "3 Néfi" ]),
      "bofm/4-ne" => book(1, corpus: :book_of_mormon, es: [ "4-nefi", "4 Nefi" ], fr: [ "4-nephi", "4 Néphi" ], en: [ "4-nephi", "4 Nephi" ], "pt-BR": [ "4-nefi", "4 Néfi" ]),
      "bofm/morm" => book(9, corpus: :book_of_mormon, es: %w[mormon Mormón], fr: %w[mormon Mormon], en: %w[mormon Mormon], "pt-BR": %w[mormon Mórmon]),
      "bofm/ether" => book(15, corpus: :book_of_mormon, es: %w[eter Éter], fr: %w[ether Éther], en: %w[ether Ether], "pt-BR": %w[eter Éter]),
      "bofm/moro" => book(10, corpus: :book_of_mormon, es: %w[moroni Moroni], fr: %w[moroni Moroni], en: %w[moroni Moroni], "pt-BR": %w[moroni Morôni]),
      "dc-testament/dc" => book(138, corpus: :doctrine_and_covenants, es: [ "secciones", "Doctrina y Convenios" ], fr: [ "sections", "Doctrine et Alliances" ], en: [ "sections", "Doctrine and Covenants" ], "pt-BR": [ "secoes", "Doutrina e Convênios" ])
    }.freeze

    Result = Data.define(:locale, :route_locale, :section, :book, :chapter, :verse, :base_study, :book_label, :corpus) do
      def citation = "#{book_label} #{chapter}:#{verse}"
      def study = "#{base_study}/#{chapter}"
    end
    BookResult = Data.define(:locale, :route_locale, :section, :book, :base_study, :book_label, :chapters, :corpus)
    ChapterResult = Data.define(:locale, :route_locale, :section, :book, :chapter, :base_study, :book_label, :corpus) do
      def citation = "#{book_label} #{chapter}"
      def study = "#{base_study}/#{chapter}"
    end
    PassageResult = Data.define(:reference, :to) do
      def citation
        verses = reference.verse == to ? reference.verse.to_s : "#{reference.verse}–#{to}"
        "#{reference.book_label} #{reference.chapter}:#{verses}"
      end
    end

    def self.resolve(locale:, section:, book:, chapter:, verse:)
      book_reference = resolve_book(locale:, section:, book:)
      return unless book_reference

      build(base_study: book_reference.base_study, book_data: BOOKS[book_reference.base_study],
        locale: book_reference.locale, route_locale: book_reference.route_locale, chapter:, verse:)
    end

    def self.resolve_book(locale:, section:, book:)
      route_locale = locale.to_s.downcase
      i18n_locale = LOCALES[route_locale]
      return unless i18n_locale

      base_study, book_data = BOOKS.find do |_study, data|
        section.to_s == SECTIONS.fetch(data[:corpus]).fetch(i18n_locale) &&
          data[:names].fetch(i18n_locale).first == book.to_s.downcase
      end
      return unless base_study && book_data

      BookResult.new(locale: i18n_locale, route_locale:, section: SECTIONS.fetch(book_data[:corpus]).fetch(i18n_locale),
        book: book_data[:names].fetch(i18n_locale).first, base_study:,
        book_label: book_data[:names].fetch(i18n_locale).last, chapters: book_data[:chapters], corpus: book_data[:corpus])
    end

    def self.resolve_chapter(locale:, section:, book:, chapter:)
      book_reference = resolve_book(locale:, section:, book:)
      chapter_number = Integer(chapter, exception: false)
      return unless book_reference && chapter_number&.between?(1, book_reference.chapters)

      ChapterResult.new(**book_reference.to_h.except(:chapters), chapter: chapter_number)
    end

    def self.from_study(study:, locale:, verse:)
      base_study, chapter = study.to_s.match(%r{\A(.+)/(\d+)\z})&.captures
      i18n_locale = locale.to_sym
      build(base_study:, book_data: BOOKS[base_study], locale: i18n_locale,
        route_locale: LOCALES.key(i18n_locale), chapter:, verse:)
    end

    def self.known_study?(study)
      base_study, chapter = study.to_s.match(%r{\A(.+)/(\d+)\z})&.captures
      book_data = BOOKS[base_study]
      book_data && chapter.to_i.between?(1, book_data[:chapters])
    end

    def self.path_options(reference, locale)
      locale = locale.to_sym
      {
        locale: LOCALES.key(locale),
        scripture_section: SECTIONS.fetch(BOOKS.fetch(reference.base_study).fetch(:corpus)).fetch(locale),
        book: BOOKS.fetch(reference.base_study).fetch(:names).fetch(locale).first,
        chapter: reference.chapter,
        verse: reference.verse
      }
    end

    def self.passage_path_options(reference, locale, to: reference.verse)
      from = reference.verse
      verse = from == to ? from : "#{from}-#{to}"
      path_options(reference, locale).merge(verse:)
    end

    def self.book_path_options(reference, locale)
      locale = locale.to_sym
      {
        locale: LOCALES.key(locale),
        scripture_section: SECTIONS.fetch(BOOKS.fetch(reference.base_study).fetch(:corpus)).fetch(locale),
        book: BOOKS.fetch(reference.base_study).fetch(:names).fetch(locale).first
      }
    end

    def self.chapter_path_options(reference, locale)
      book_path_options(reference, locale).merge(chapter: reference.chapter)
    end

    def self.books(locale = :es)
      locale = locale.to_sym
      BOOKS.map do |base_study, data|
        BookResult.new(locale:, route_locale: LOCALES.key(locale), section: SECTIONS.fetch(data[:corpus]).fetch(locale),
          book: data[:names].fetch(locale).first, base_study:,
          book_label: data[:names].fetch(locale).last, chapters: data[:chapters], corpus: data[:corpus])
      end
    end

    def self.chapters(locale = :es)
      books(locale).flat_map do |book_reference|
        (1..book_reference.chapters).map do |chapter|
          ChapterResult.new(**book_reference.to_h.except(:chapters), chapter:)
        end
      end
    end

    def self.indexable_references
      indexable_passages.map(&:reference)
    end

    def self.indexable_passages
      quiz_references = QuizDefinition.catalog.all_questions.filter_map do |question|
        study = question.scripture.study
        next unless known_study?(study)

        verses = Scriptures::Read.focus_verses(question.scripture.cite)
        reference = from_study(study:, locale: :es, verse: verses.first) if verses.any?
        PassageResult.new(reference:, to: verses.last) if reference
      end
      manual = PassageResult.new(
        reference: resolve(locale: "es", section: "biblia", book: "2-samuel", chapter: 2, verse: 1),
        to: 1
      )
      (quiz_references + [ manual ]).compact.uniq do |passage|
        [ passage.reference.study, passage.reference.verse, passage.to ]
      end
    end

    def self.build(base_study:, book_data:, locale:, route_locale:, chapter:, verse:)
      chapter_number = Integer(chapter, exception: false)
      verse_number = Integer(verse, exception: false)
      return unless base_study && book_data && route_locale
      return unless chapter_number&.between?(1, book_data[:chapters])
      return unless verse_number&.between?(1, 176)

      Result.new(
        locale:, route_locale:, section: SECTIONS.fetch(book_data[:corpus]).fetch(locale),
        book: book_data[:names].fetch(locale).first,
        chapter: chapter_number, verse: verse_number, base_study:,
        book_label: book_data[:names].fetch(locale).last, corpus: book_data[:corpus]
      )
    end
    private_class_method :build
  end
end
