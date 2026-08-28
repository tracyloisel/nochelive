class ScripturesController < ApplicationController
  helper_method :scripture_corpus_label, :scripture_corpus_path
  def book
    @book = Scriptures::Reference.resolve_book(
      locale: params[:locale], section: params[:scripture_section], book: params[:book]
    )
    return head :not_found unless @book

    @chapters = (1..@book.chapters).to_a
    chapter_references = @chapters.map { |chapter| "#{@book.base_study}/#{chapter}" }
    @chapter_reads = ScriptureChapterStat.where(reference: chapter_references).pluck(:reference, :reads_count).to_h
    @chapter_order = params[:order] == "popular" ? "popular" : "scripture"
    if @chapter_order == "popular"
      @chapters.sort_by! { |chapter| [ -@chapter_reads.fetch("#{@book.base_study}/#{chapter}", 0), chapter ] }
    end
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

    @scripture_illustrations = Scriptures::Illustrations.call(chapter: @chapter, locale: @reference.locale)
    @previous_chapter = chapter_neighbor(-1)
    @next_chapter = chapter_neighbor(1)
    configure_chapter_seo
  end

  def passage
    passage_from, passage_to = passage_range(params[:verse])
    return head :not_found unless passage_from

    @reference = Scriptures::Reference.resolve(
      locale: params[:locale],
      section: params[:scripture_section],
      book: params[:book],
      chapter: params[:chapter],
      verse: passage_from
    )
    return head :not_found unless @reference

    @passage_from = passage_from
    @passage_to = passage_to
    @passage_verse_label = passage_from == passage_to ? passage_from.to_s : "#{passage_from}–#{passage_to}"
    @passage_reference = "#{@reference.book_label} #{@reference.chapter}:#{@passage_verse_label}"
    @study = @reference.study
    @cite = @passage_reference
    @chapter = Scriptures::Read.call(
      study: @reference.study,
      locale: @reference.locale,
      cite: @passage_reference,
      public: true
    )
    return head :service_unavailable unless @chapter

    @selected_verses = @chapter.verses.select { |verse| verse.number.between?(passage_from, passage_to) }
    return head :not_found unless @selected_verses.first&.number == passage_from && @selected_verses.last&.number == passage_to

    @verse = @selected_verses.first
    @context = @chapter.verses.select { |verse| verse.number.between?(passage_from - 1, passage_to + 1) }
    @previous_verse = @chapter.verses.select { |verse| verse.number < passage_from }.max_by(&:number)
    @next_verse = @chapter.verses.select { |verse| verse.number > passage_to }.min_by(&:number)
    @source_url = @chapter.source_url
    @scripture_illustrations = Scriptures::Illustrations.call(chapter: @chapter, locale: @reference.locale)
    @scripture_reads_count = ScriptureChapterStat.count_for(@study)
    assign_scripture_highlights
    configure_passage_seo
    Rails.logger.info("event=seo_scripture reference=#{@reference.study}:#{@passage_verse_label} locale=#{@reference.route_locale}")
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
    @scripture_illustrations = Scriptures::Illustrations.call(chapter: @chapter) if @chapter
    @scripture_reads_count = ScriptureChapterStat.count_for(@study) if @chapter
    assign_scripture_highlights if @chapter
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
      image = scripture_illustration_url
      index_for_search!(title:, description:, canonical:,
        image:,
        alternates: chapter_alternates(@reference),
        structured_data: scripture_graph(title:, description:, canonical:, image:, crumbs: [
          corpus_crumb(@reference),
          [ @reference.book_label, scripture_book_url(**Scriptures::Reference.book_path_options(@reference, @reference.locale)) ],
          [ @reference.citation, canonical ]
        ]))
    end

    def configure_passage_seo
      title = t("seo.scripture.title", reference: @passage_reference)
      description = t(
        "seo.scripture.description",
        reference: @passage_reference,
        verse: @selected_verses.map(&:text).join(" ").truncate(125)
      )
      canonical = scripture_passage_url(
        **Scriptures::Reference.passage_path_options(@reference, @reference.locale, to: @passage_to)
      )
      alternates = I18n.available_locales.to_h do |locale|
        [ locale.to_s.downcase, scripture_passage_url(
          **Scriptures::Reference.passage_path_options(@reference, locale, to: @passage_to)
        ) ]
      end
      alternates["x-default"] = scripture_passage_url(
        **Scriptures::Reference.passage_path_options(@reference, :es, to: @passage_to)
      )

      index_for_search!(
        title:,
        description:,
        canonical:,
        image: scripture_illustration_url(@passage_from),
        alternates:,
        structured_data: scripture_graph(title:, description:, canonical:, crumbs: [
          corpus_crumb(@reference),
          [ @reference.book_label, scripture_book_url(**Scriptures::Reference.book_path_options(@reference, @reference.locale)) ],
          [ "#{@reference.book_label} #{@reference.chapter}", scripture_chapter_url(**Scriptures::Reference.chapter_path_options(@reference, @reference.locale)) ],
          [ @passage_reference, canonical ]
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

    def scripture_graph(title:, description:, canonical:, crumbs:, image: nil)
      page = {
        "@type": "WebPage", name: title, description:, url: canonical,
        inLanguage: I18n.locale.to_s,
        isPartOf: { "@type": "WebSite", name: "Noche Live", url: discovery_page_url(:home, I18n.locale) }
      }
      page[:primaryImageOfPage] = { "@type": "ImageObject", contentUrl: image } if image

      {
        "@context": "https://schema.org",
        "@graph": [
          page,
          {
            "@type": "BreadcrumbList",
            itemListElement: crumbs.each_with_index.map do |(name, item), index|
              { "@type": "ListItem", position: index + 1, name:, item: }
            end
          }
        ]
      }
    end

    def scripture_illustration_url(anchor = nil)
      illustrations = Array(@scripture_illustrations)
      illustration = anchor ? illustrations.min_by { |item| (item.anchor_verse - anchor).abs } : illustrations.first
      "#{request.base_url}/media/#{illustration.image}" if illustration
    end

    def passage_range(value)
      from, to = value.to_s.split("-", 2).map { |part| Integer(part, exception: false) }
      to ||= from
      return unless from&.between?(1, 176) && to&.between?(from, 176)

      [ from, to ]
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

    def assign_scripture_highlights
      @scripture_highlights = current_street_person&.scripture_highlights
        &.for_reader(reference: @study, locale: I18n.locale)
        &.map(&:reader_attributes) || []
    end
end
