class ScripturesController < ApplicationController
  helper_method :scripture_corpus_label, :scripture_corpus_path
  def book
    @book = Scriptures::Reference.resolve_book(
      locale: params[:locale], section: params[:scripture_section], book: params[:book]
    )
    return head :not_found unless @book

    @chapters = (1..@book.chapters)
    configure_book_seo
  end

  def chapter
    @reference = Scriptures::Reference.resolve_chapter(
      locale: params[:locale], section: params[:scripture_section],
      book: params[:book], chapter: params[:chapter]
    )
    return head :not_found unless @reference

    @chapter = Scriptures::Read.call(study: @reference.study, locale: @reference.locale, public: true)
    return head :service_unavailable unless @chapter

    @previous_chapter = chapter_neighbor(-1)
    @next_chapter = chapter_neighbor(1)
    configure_chapter_seo
  end

  def passage
    @reference = Scriptures::Reference.resolve(
      locale: params[:locale],
      section: params[:scripture_section],
      book: params[:book],
      chapter: params[:chapter],
      verse: params[:verse]
    )
    return head :not_found unless @reference

    @chapter = Scriptures::Read.call(
      study: @reference.study,
      locale: @reference.locale,
      cite: @reference.citation,
      public: true
    )
    return head :service_unavailable unless @chapter

    @verse = @chapter&.verses&.find { |verse| verse.number == @reference.verse }
    return head :not_found unless @verse

    @context = @chapter.verses.select { |verse| (verse.number - @reference.verse).abs <= 1 }
    @previous_verse = @chapter.verses.select { |verse| verse.number < @reference.verse }.max_by(&:number)
    @next_verse = @chapter.verses.select { |verse| verse.number > @reference.verse }.min_by(&:number)
    configure_passage_seo
    Rails.logger.info("event=seo_scripture reference=#{@reference.study}:#{@reference.verse} locale=#{@reference.route_locale}")
  end

  def show
    @study = params[:study].to_s
    unless Quizzes::Scripture.known_study?(@study)
      head :not_found
      return
    end

    @cite = params[:cite].to_s
    @source_url = Quizzes::Scripture.page_url(@study)
    @chapter = Scriptures::Read.call(study: @study, locale: I18n.locale, cite: @cite)
    remember_study_reading if @chapter
    render :frame, layout: false if turbo_frame_request?
  end

  private

    def configure_book_seo
      title = t("seo.scripture.book_title", book: @book.book_label)
      description = t("seo.scripture.book_description", book: @book.book_label, chapters: @book.chapters)
      canonical = scripture_book_url(**Scriptures::Reference.book_path_options(@book, @book.locale))
      index_for_search!(title:, description:, canonical:,
        alternates: book_alternates(@book),
        structured_data: scripture_graph(title:, description:, canonical:, crumbs: [
          corpus_crumb(@book),
          [ @book.book_label, canonical ]
        ]))
    end

    def configure_chapter_seo
      title = t("seo.scripture.chapter_title", reference: @reference.citation)
      description = t("seo.scripture.chapter_description", reference: @reference.citation,
        summary: @chapter.summary.presence || t("seo.scripture.chapter_fallback"))
      canonical = scripture_chapter_url(**Scriptures::Reference.chapter_path_options(@reference, @reference.locale))
      index_for_search!(title:, description:, canonical:,
        alternates: chapter_alternates(@reference),
        structured_data: scripture_graph(title:, description:, canonical:, crumbs: [
          corpus_crumb(@reference),
          [ @reference.book_label, scripture_book_url(**Scriptures::Reference.book_path_options(@reference, @reference.locale)) ],
          [ @reference.citation, canonical ]
        ]))
    end

    def configure_passage_seo
      title = t("seo.scripture.title", reference: @reference.citation)
      description = t(
        "seo.scripture.description",
        reference: @reference.citation,
        verse: @verse.text.truncate(125)
      )
      canonical = scripture_passage_url(**Scriptures::Reference.path_options(@reference, @reference.locale))
      alternates = I18n.available_locales.to_h do |locale|
        [ locale.to_s.downcase, scripture_passage_url(**Scriptures::Reference.path_options(@reference, locale)) ]
      end
      alternates["x-default"] = scripture_passage_url(**Scriptures::Reference.path_options(@reference, :es))

      index_for_search!(
        title:,
        description:,
        canonical:,
        alternates:,
        structured_data: scripture_graph(title:, description:, canonical:, crumbs: [
          corpus_crumb(@reference),
          [ @reference.book_label, scripture_book_url(**Scriptures::Reference.book_path_options(@reference, @reference.locale)) ],
          [ "#{@reference.book_label} #{@reference.chapter}", scripture_chapter_url(**Scriptures::Reference.chapter_path_options(@reference, @reference.locale)) ],
          [ @reference.citation, canonical ]
        ])
      )
    end

    def book_alternates(reference)
      localized_alternates { |locale| scripture_book_url(**Scriptures::Reference.book_path_options(reference, locale)) }
    end

    def chapter_alternates(reference)
      localized_alternates { |locale| scripture_chapter_url(**Scriptures::Reference.chapter_path_options(reference, locale)) }
    end

    def localized_alternates
      alternates = I18n.available_locales.to_h { |locale| [ locale.to_s.downcase, yield(locale) ] }
      alternates["x-default"] = yield(:es)
      alternates
    end

    def discovery_page_url(key, locale)
      options = Seo::DiscoveryPage.path_options(key, locale)
      options[:slug].present? ? discovery_url(**options) : discovery_home_url(locale: options[:locale])
    end

    def scripture_graph(title:, description:, canonical:, crumbs:)
      {
        "@context": "https://schema.org",
        "@graph": [
          {
            "@type": "WebPage", name: title, description:, url: canonical,
            inLanguage: I18n.locale.to_s,
            isPartOf: { "@type": "WebSite", name: "Noche Live", url: discovery_page_url(:home, I18n.locale) }
          },
          {
            "@type": "BreadcrumbList",
            itemListElement: crumbs.each_with_index.map do |(name, item), index|
              { "@type": "ListItem", position: index + 1, name:, item: }
            end
          }
        ]
      }
    end

    def chapter_neighbor(offset)
      number = @reference.chapter + offset
      return unless number.between?(1, Scriptures::Reference::BOOKS.fetch(@reference.base_study)[:chapters])

      Scriptures::Reference.resolve_chapter(
        locale: @reference.route_locale, section: @reference.section,
        book: @reference.book, chapter: number
      )
    end

    def corpus_crumb(reference)
      [ scripture_corpus_label(reference), scripture_corpus_path(reference) ]
    end

    def scripture_corpus_label(reference)
      t("seo.scripture.corpora.#{reference.corpus}")
    end

    def scripture_corpus_path(reference)
      key = reference.corpus == :bible ? :bible_study : :home
      discovery_page_url(key, reference.locale)
    end

    def remember_study_reading
      person = current_street_person
      unit = StudyUnit.find_by(id: params[:study_unit_id])
      quiz = unit&.published_quiz
      return unless person && quiz
      return unless quiz.readings.any? { |reading| reading["study"] == @study }

      ReadingProgress.find_or_create_by!(person:, study_unit: unit, reference: @study) do |progress|
        progress.status = "opened"
      end
    end
end
