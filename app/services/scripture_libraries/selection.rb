require "base64"
require "time"

module ScriptureLibraries
  # Builds the only drill-down used to choose a scripture reading. The result
  # deliberately contains plain presentation data so the library remains fully
  # navigable without JavaScript; Turbo can enhance the same links in place.
  class Selection
    Item = Data.define(:title, :detail, :path, :kind, :icon, :progress, :reader)
    Breadcrumb = Data.define(:label, :path)
    WeeklyFeature = Data.define(
      :week_id, :title, :period, :corpus,
      :reading_completed_count, :reading_total_count, :reading_progress,
      :expedition_title, :expedition_promise, :expedition_path,
      :expedition_completed_count, :expedition_total_count, :expedition_progress
    )
    Result = Data.define(:key, :title_key, :lede_key, :items, :breadcrumbs, :empty_key, :feature)

    SECTIONS = %w[weekly bookmarks canon program].freeze
    BOOKMARK_PAGE_SIZE = 12
    COLLECTIONS = {
      old_testament: ->(book) { book.base_study.start_with?("ot/") },
      new_testament: ->(book) { book.base_study.start_with?("nt/") },
      book_of_mormon: ->(book) { book.corpus == :book_of_mormon },
      doctrine_and_covenants: ->(book) { book.corpus == :doctrine_and_covenants }
    }.freeze
    ANCHORS = {
      weekly: "cette-semaine",
      bookmarks: "mes-signets",
      canon: "mes-ecritures",
      program: "programme-annuel"
    }.freeze

    def self.call(person:, locale:, section:, collection: nil, book: nil, unit: nil, cursor: nil, preview: false)
      new(person:, locale:, section:, collection:, book:, unit:, cursor:, preview:).call
    end

    def initialize(person:, locale:, section:, collection:, book:, unit:, cursor:, preview:)
      @person = person
      @locale = Locale.i18n(locale)
      @section = section.to_s
      @collection = collection.to_s.presence
      @book = book.to_s.presence
      @unit_id = unit.to_s.presence
      @cursor = cursor.to_s.presence
      @preview = preview
      @routes = Rails.application.routes.url_helpers
    end

    def call
      return unless SECTIONS.include?(@section)

      case @section
      when "weekly" then weekly
      when "bookmarks" then bookmarks
      when "canon" then canon
      when "program" then program
      end
    end

    private

      def weekly
        week = selected_week || current_week
        items = @preview ? preview_readings : reading_items(week)
        feature = @preview ? preview_weekly_feature : weekly_feature(week, items:)
        result(:weekly, items:, breadcrumbs: week_breadcrumbs(week), feature:)
      end

      def bookmarks
        return result(:bookmarks, items: preview_bookmarks) if @preview

        rows = bookmark_scope.limit(BOOKMARK_PAGE_SIZE + 1).to_a
        has_more = rows.size > BOOKMARK_PAGE_SIZE
        marks = rows.first(BOOKMARK_PAGE_SIZE)
        items = marks.filter_map { |mark| bookmark_item(mark) }
        items << bookmark_more_item(marks.last) if has_more && marks.last
        result(:bookmarks, items:)
      end

      def canon
        collection_key = valid_collection
        return canon_collections unless @collection
        return canon_collections unless collection_key

        books = books_for(collection_key)
        selected_book = books.find { |candidate| candidate.base_study == @book }
        return canon_books(collection_key, books) unless @book
        return canon_books(collection_key, books) unless selected_book

        canon_chapters(collection_key, selected_book)
      end

      def program
        if @preview && @unit_id == "preview"
          return result(:program, items: preview_readings, breadcrumbs: [
            Breadcrumb.new(label: t("scripture_library.preview.annual_title"), path: nil)
          ])
        end

        return result(:program, items: preview_program_weeks) if @preview

        week = selected_week
        return program_weeks unless @unit_id
        return program_weeks unless week

        result(:program, items: reading_items(week), breadcrumbs: program_breadcrumbs(week))
      end

      def result(key, items:, breadcrumbs: [], empty_key: nil, feature: nil)
        prefix = "scripture_library.selection.#{key}"
        Result.new(
          key: { canon: :collection, program: :annual }.fetch(key, key),
          title_key: "#{prefix}.title", lede_key: "#{prefix}.lede",
          items:, breadcrumbs:, empty_key: empty_key || "#{prefix}.empty", feature:
        )
      end

      def weekly_feature(week, items:)
        return unless week

        quiz = week.published_quiz
        expedition = Expeditions::Presentation.call(quiz:, person: @person, locale: @locale) if quiz&.expedition?
        reading_total = items.count { |item| item.kind == :reading }
        reading_completed = items.count { |item| item.kind == :reading && item.progress == 1.0 }
        WeeklyFeature.new(
          week_id: week.id,
          title: week.theme(@locale),
          period: week.display_period(@locale),
          corpus: week.display_scripture_refs(@locale).join(" ; "),
          reading_completed_count: reading_completed,
          reading_total_count: reading_total,
          reading_progress: ratio_including_zero(reading_completed, reading_total),
          expedition_title: expedition&.title,
          expedition_promise: expedition&.promise,
          expedition_path: expedition && @routes.street_map_path(
            view: "expeditions",
            expedition: expedition.study_unit_id
          ),
          expedition_completed_count: expedition&.completed_count,
          expedition_total_count: expedition&.total_count,
          expedition_progress: ratio_including_zero(
            expedition&.completed_count,
            expedition&.total_count
          )
        )
      end

      def preview_weekly_feature
        WeeklyFeature.new(
          week_id: "preview",
          title: t("scripture_library.preview.weekly_title"),
          period: t("scripture_library.preview.annual_detail"),
          corpus: "Psaumes 102–150",
          reading_completed_count: 1,
          reading_total_count: 3,
          reading_progress: 1.0 / 3,
          expedition_title: t("scripture_library.preview.expedition_title"),
          expedition_promise: t("scripture_library.preview.expedition_detail"),
          expedition_path: @routes.street_map_path(view: "expeditions"),
          expedition_completed_count: 2,
          expedition_total_count: 6,
          expedition_progress: 2.0 / 6
        )
      end

      def reading_items(week)
        quiz = week&.published_quiz
        readings = Array(quiz&.readings(@locale)).filter_map do |reading|
          study = reading["study"].to_s
          next unless Scriptures::Reference.known_study?(study)

          reading.merge("study" => study)
        end.uniq { |reading| reading.fetch("study") }
        return [] if readings.empty?

        progress_by_study = reading_progresses(readings.map { |reading| reading.fetch("study") })
        readings.filter_map do |reading|
          study = reading.fetch("study")
          reference = Scriptures::Reference.from_study(study:, locale: @locale, verse: 1)
          next unless reference

          title = "#{reference.book_label} #{reference.chapter}"
          cite = reading["label"].presence || title
          Item.new(
            title:, detail: cite == title ? week&.theme(@locale) : cite,
            path: @routes.scripture_path(study, cite:, study_unit_id: week&.id, locale: @locale),
            kind: :reading, icon: "scripture-book",
            progress: progress_ratio(progress_by_study[study]), reader: true
          )
        end
      end

      def preview_readings
        [
          "ot/ps/49", "ot/ps/50", "ot/ps/51"
        ].filter_map do |study|
          reference = Scriptures::Reference.from_study(study:, locale: @locale, verse: 1)
          next unless reference

          title = "#{reference.book_label} #{reference.chapter}"
          Item.new(
            title:, detail: title, path: @routes.scripture_path(study, cite: title, locale: @locale),
            kind: :reading, icon: "scripture-book",
            progress: study.end_with?("/49") ? 0.58 : nil, reader: true
          )
        end
      end

      def bookmark_scope
        return ScriptureMark.none unless @person

        scope = @person.scripture_marks.active.where.not(bookmarked_at: nil)
          .order(bookmarked_at: :desc, id: :desc)
        timestamp, id = decode_cursor(@cursor)
        return scope unless timestamp && id

        scope.where(
          "bookmarked_at < :timestamp OR (bookmarked_at = :timestamp AND id < :id)",
          timestamp:, id:
        )
      end

      def bookmark_item(mark)
        verse = mark.start_verse || 1
        reference = Scriptures::Reference.from_study(study: mark.reference, locale: @locale, verse:)
        return unless reference

        citation = bookmark_citation(reference, mark)
        Item.new(
          title: citation,
          detail: (mark.note_body.presence || mark.selected_text.presence)&.squish&.truncate(110),
          path: @routes.scripture_path(mark.reference, cite: citation, locale: @locale),
          kind: :bookmark, icon: "bookmark", progress: nil, reader: true
        )
      end

      def bookmark_citation(reference, mark)
        return "#{reference.book_label} #{reference.chapter}" unless mark.start_verse

        verses = if mark.end_verse.present? && mark.end_verse != mark.start_verse
          "#{mark.start_verse}–#{mark.end_verse}"
        else
          mark.start_verse.to_s
        end
        "#{reference.book_label} #{reference.chapter}:#{verses}"
      end

      def bookmark_more_item(mark)
        Item.new(
          title: t("scripture_library.selection.more", default: t("scripture_reader.selection.more", default: "…")),
          detail: nil,
          path: library_path(:bookmarks, cursor: encode_cursor(mark)),
          kind: :pagination, icon: "arrow", progress: nil, reader: false
        )
      end

      def encode_cursor(mark)
        value = [ mark.bookmarked_at.utc.iso8601(6), mark.id ].join("|")
        Base64.urlsafe_encode64(value, padding: false)
      end

      def decode_cursor(cursor)
        return unless cursor

        timestamp, id = Base64.urlsafe_decode64(cursor).split("|", 2)
        parsed_id = Integer(id, exception: false)
        parsed_time = Time.iso8601(timestamp)
        return unless parsed_id&.positive?

        [ parsed_time, parsed_id ]
      rescue ArgumentError
        nil
      end

      def preview_bookmarks
        [
          [ "ot/ps/49", 17 ], [ "nt/john/3", 16 ], [ "bofm/1-ne/5", 1 ], [ "dc-testament/dc/48", 10 ]
        ].filter_map do |study, verse|
          reference = Scriptures::Reference.from_study(study:, locale: @locale, verse:)
          next unless reference

          Item.new(
            title: reference.citation, detail: nil,
            path: @routes.scripture_path(study, cite: reference.citation, locale: @locale),
            kind: :bookmark, icon: "bookmark", progress: nil, reader: true
          )
        end
      end

      def preview_program_weeks
        [ 34, 35, 36 ].map do |number|
          Item.new(
            title: t("scripture_library.annual.week", number:, heading: t("scripture_library.preview.weekly_title")),
            detail: t("scripture_library.preview.annual_detail"),
            path: library_path(:program, unit: "preview"), kind: :week,
            icon: "calendar", progress: number == 34 ? 7.0 / 12 : nil, reader: false
          )
        end
      end

      def canon_collections
        books = Scriptures::Reference.books(@locale)
        items = COLLECTIONS.map do |key, matcher|
          collection_books = books.select(&matcher)
          total_chapters = collection_books.sum(&:chapters)
          read_count = completed_references.count do |study|
            collection_books.any? { |book| study.start_with?("#{book.base_study}/") }
          end
          Item.new(
            title: t("scripture_library.collections.#{key}"),
            detail: t("scripture_library.selection.canon.book_count", count: collection_books.size,
              default: collection_books.size.to_s),
            path: library_path(:canon, collection: key), kind: :collection,
            icon: "scripture-book", progress: ratio(read_count, total_chapters), reader: false
          )
        end
        result(:canon, items:)
      end

      def canon_books(collection_key, books)
        items = books.map do |book|
          prefix = "#{book.base_study}/"
          read_count = completed_references.count { |study| study.start_with?(prefix) }
          Item.new(
            title: book.book_label,
            detail: t("scripture_library.selection.canon.chapter_count", count: book.chapters,
              default: book.chapters.to_s),
            path: library_path(:canon, collection: collection_key, book: book.base_study),
            kind: :book, icon: "book", progress: ratio(read_count, book.chapters), reader: false
          )
        end
        result(:canon, items:, breadcrumbs: [
          Breadcrumb.new(label: t("scripture_library.rows.collection"), path: library_path(:canon)),
          Breadcrumb.new(label: t("scripture_library.collections.#{collection_key}"), path: nil)
        ])
      end

      def canon_chapters(collection_key, book)
        studies = (1..book.chapters).map { |chapter| "#{book.base_study}/#{chapter}" }
        progress_by_study = reading_progresses(studies)
        items = studies.each_with_index.map do |study, index|
          chapter = index + 1
          progress = progress_by_study[study]
          title = "#{book.book_label} #{chapter}"
          Item.new(
            title:, detail: chapter_progress_detail(progress),
            path: @routes.scripture_path(study, cite: title, locale: @locale), kind: :chapter,
            icon: "scripture-book", progress: progress_ratio(progress), reader: true
          )
        end
        result(:canon, items:, breadcrumbs: [
          Breadcrumb.new(label: t("scripture_library.rows.collection"), path: library_path(:canon)),
          Breadcrumb.new(label: t("scripture_library.collections.#{collection_key}"),
            path: library_path(:canon, collection: collection_key)),
          Breadcrumb.new(label: book.book_label, path: nil)
        ])
      end

      def valid_collection
        @collection&.to_sym if COLLECTIONS.key?(@collection&.to_sym)
      end

      def books_for(collection_key)
        Scriptures::Reference.books(@locale).select(&COLLECTIONS.fetch(collection_key))
      end

      def program_weeks
        program = latest_program
        weeks = program&.study_units&.weeks&.includes(:study_quiz_versions)&.to_a || []
        items = week_items(weeks)
        breadcrumbs = if program
          [ Breadcrumb.new(label: program.display_title(@locale), path: nil) ]
        else
          []
        end
        result(:program, items:, breadcrumbs:)
      end

      def week_items(weeks)
        studies_by_week = weeks.to_h do |week|
          readings = Array(week.published_quiz&.readings(@locale))
          [ week.id, readings.filter_map { |reading| reading["study"].presence }.uniq ]
        end
        progresses = reading_progresses(studies_by_week.values.flatten.uniq)

        weeks.map.with_index(1) do |week, index|
          studies = studies_by_week.fetch(week.id)
          completed = studies.count { |study| progresses[study]&.completed_at.present? }
          Item.new(
            title: t("scripture_library.annual.week", number: index, heading: week.display_heading(@locale)),
            detail: [ week.display_period(@locale), week.display_scripture_refs(@locale).join(" ; ") ].compact_blank.join(" · "),
            path: library_path(:program, unit: week.id), kind: :week,
            icon: "calendar", progress: ratio(completed, studies.size), reader: false
          )
        end
      end

      def selected_week
        return if @unit_id.blank? || @unit_id == "preview"

        id = Integer(@unit_id, exception: false)
        return unless id&.positive?

        StudyUnit.joins(:study_program).where(
          id:, kind: "week", study_programs: { status: "published" }
        ).first
      end

      def current_week
        program = latest_program
        return unless program

        program.current_week || program.study_units.weeks.min_by do |week|
          ((week.starts_on || Date.current) - Date.current).abs
        end
      end

      def latest_program
        @latest_program ||= StudyProgram.where(status: "published").order(year: :desc).first
      end

      def week_breadcrumbs(week)
        return [] unless week

        [ Breadcrumb.new(label: week.display_heading(@locale), path: nil) ]
      end

      def program_breadcrumbs(week)
        [
          Breadcrumb.new(label: week.study_program.display_title(@locale), path: library_path(:program)),
          Breadcrumb.new(label: week.display_heading(@locale), path: nil)
        ]
      end

      def reading_progresses(studies)
        return {} unless @person && studies.any?

        @person.scripture_reading_progresses.where(locale: @locale.to_s, reference: studies).index_by(&:reference)
      end

      def completed_references
        return [] unless @person

        @completed_references ||= @person.scripture_reading_progresses
          .where(locale: @locale.to_s).where.not(completed_at: nil).distinct.pluck(:reference)
      end

      def progress_ratio(progress)
        return unless progress
        return 1.0 if progress.completed_at.present?

        value = progress.progress_ratio.to_f.clamp(0.0, 1.0)
        value.positive? ? value : nil
      end

      def chapter_progress_detail(progress)
        return t("scripture_library.selection.canon.completed", default: "✓") if progress&.completed_at.present?
        return t("scripture_library.selection.canon.in_progress", percent: (progress.progress_ratio.to_f * 100).round,
          default: "#{(progress.progress_ratio.to_f * 100).round}%") if progress_ratio(progress)

        nil
      end

      def ratio(numerator, denominator)
        return if denominator.to_i <= 0 || numerator.to_i <= 0

        numerator.fdiv(denominator).clamp(0.0, 1.0)
      end

      def ratio_including_zero(numerator, denominator)
        return unless denominator.to_i.positive?

        numerator.to_i.fdiv(denominator.to_i).clamp(0.0, 1.0)
      end

      def library_path(section, **options)
        @routes.scripture_library_path(
          **options, section:, locale: @locale, preview: (@preview ? 1 : nil), anchor: ANCHORS.fetch(section)
        )
      end

      def t(key, **options)
        I18n.t(key, locale: @locale, **options)
      end
  end
end
