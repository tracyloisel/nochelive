module ScriptureLibraries
  class Screen
    Row = Data.define(:title, :detail, :meta, :path, :progress, :icon, :avatars)
    Result = Data.define(:quote, :resume, :recommendation, :weekly, :bookmarks, :collection, :rama, :annual)

    COLLECTIONS = {
      old_testament: "ot/",
      new_testament: "nt/",
      book_of_mormon: "bofm/",
      doctrine_and_covenants: "dc-testament/"
    }.freeze

    def self.call(person:, locale:, on: Date.current, preview: false)
      new(person:, locale:, on:, preview:).call
    end

    def initialize(person:, locale:, on:, preview:)
      @person = person
      @locale = Locale.i18n(locale)
      @on = on.to_date
      @preview = preview
      @routes = Rails.application.routes.url_helpers
    end

    def call
      return preview_result if @preview

      @program = StudyProgram.where(status: "published").order(year: :desc).first
      @week = @program&.current_week(on: @on)
      @quiz = @week&.published_quiz
      Result.new(
        quote: editorial_quote,
        resume: resume_row,
        recommendation: recommendation_row,
        weekly: weekly_row,
        bookmarks: bookmarks_row,
        collection: collection_row,
        rama: rama_row,
        annual: annual_row
      )
    end

    private

      def t(key, **options)
        I18n.t("scripture_library.#{key}", locale: @locale, **options)
      end

      def editorial_quote
        @quiz&.content&.dig("light", @locale.to_s).presence ||
          t("hero.fallback_quote")
      end

      def resume_row
        progress = @person&.scripture_reading_progresses&.select(&:resumable?)&.max_by(&:last_opened_at)
        return empty_row(:resume, "scripture-book") unless progress

        reference = Scriptures::Reference.from_study(study: progress.reference, locale: @locale, verse: progress.last_verse)
        return empty_row(:resume, "scripture-book") unless reference

        Row.new(
          title: reference.citation,
          detail: t("resume.progress", verse: progress.last_verse, percent: (progress.progress_ratio.to_f * 100).round),
          meta: t("actions.continue"), path: @routes.scripture_path(progress.reference, cite: reference.citation, locale: @locale),
          progress: progress.progress_ratio.to_f, icon: "scripture-book", avatars: []
        )
      end

      def recommendation_row
        suggestion = Quizzes::ReadingSuggestions.call(person: @person, limit: 1).first
        return empty_row(:recommendation, "sparkle") unless suggestion

        reference = Scriptures::Reference.from_study(study: suggestion.study, locale: @locale, verse: 1)
        cite = localized_cite(suggestion.cite, reference)
        Row.new(
          title: cite,
          detail: t("recommendation.reason"), meta: t("actions.read"),
          path: @routes.scripture_path(suggestion.study, cite: cite, locale: @locale), progress: nil,
          icon: "sparkle", avatars: []
        )
      end

      def weekly_row
        readings = Array(@quiz&.readings(@locale)).uniq { |reading| reading["study"] }
        return empty_row(:weekly, "calendar") unless @week && readings.any?

        completed = if @person
          @person.scripture_reading_progresses.where(locale: @locale.to_s, reference: readings.pluck("study"))
            .where.not(completed_at: nil).count
        else
          0
        end
        Row.new(
          title: @week.theme(@locale), detail: @week.display_scripture_refs(@locale).join(" ; "),
          meta: t("actions.open"), path: library_section_path(:weekly, anchor: "cette-semaine", unit: @week.id),
          progress: completed.fdiv(readings.size), icon: "calendar", avatars: []
        )
      end

      def bookmarks_row
        marks = @person ? @person.scripture_marks.active.where.not(bookmarked_at: nil).order(bookmarked_at: :desc, id: :desc) : ScriptureMark.none
        last = marks.first
        detail = if last
          reference = Scriptures::Reference.from_study(study: last.reference, locale: @locale, verse: last.start_verse || 1)
          text = last.note_body.presence || last.selected_text.presence
          [ reference&.citation, text&.truncate(56) ].compact.join(" — ")
        else
          t("bookmarks.empty")
        end
        Row.new(title: t("bookmarks.count", count: marks.count), detail:, meta: t("actions.find"),
          path: library_section_path(:bookmarks, anchor: "mes-signets"), progress: nil, icon: "bookmark", avatars: [])
      end

      def collection_row
        references = if @person
          (@person.scripture_chapter_reads.distinct.pluck(:reference) + @person.scripture_marks.active.distinct.pluck(:reference)).uniq
        else
          []
        end
        key, count = COLLECTIONS.map { |name, prefix| [ name, references.count { |reference| reference.start_with?(prefix) } ] }.max_by(&:last)
        key ||= :old_testament
        Row.new(title: t("collections.#{key}"), detail: t("collection.progress", count:), meta: t("actions.explore"),
          path: library_section_path(:canon, anchor: "mes-ecritures", collection: key), progress: nil, icon: "book", avatars: [])
      end

      def rama_row
        studies = Array(@quiz&.readings(@locale)).filter_map { |reading| reading["study"].presence }
        member_ids = if @person&.ward && studies.any?
          ScriptureReadingProgress.joins(:person)
            .where(people: { ward_id: @person.ward_id }, reference: studies)
            .where.not(completed_at: nil).distinct.pluck(:person_id) - [ @person.id ]
        else
          []
        end
        members = @person&.ward&.people&.where(id: member_ids)&.order(:given_name)&.to_a || []
        people = members.first(4)
        path = @routes.scripture_circle_path(locale: @locale) if @person&.ward&.scripture_circle_readable?
        detail = path ? t("rama.detail") : t("rama.unavailable")
        meta = path ? t("actions.join") : t("rama.unavailable_action")
        Row.new(title: t("rama.reading_together", count: members.size), detail:, meta:,
          path:, progress: nil, icon: "people", avatars: people)
      end

      def annual_row
        return empty_row(:annual, "calendar") unless @program

        weeks = @program.study_units.weeks.to_a
        return empty_row(:annual, "calendar") if weeks.empty?

        week = @week || weeks.min_by { |unit| ((unit.starts_on || @on) - @on).abs }
        return empty_row(:annual, "calendar") unless week

        index = weeks.index(week).to_i + 1
        Row.new(title: t("annual.week", number: index, heading: week.display_heading(@locale)),
          detail: week.display_period(@locale), meta: t("actions.see_year"),
          path: library_section_path(:program, anchor: "programme-annuel", unit: week.id),
          progress: index.fdiv([ weeks.size, 1 ].max), icon: "calendar", avatars: [])
      end

      def empty_row(name, icon)
        section, anchor = case name.to_sym
        when :weekly then [ :weekly, "cette-semaine" ]
        when :annual then [ :program, "programme-annuel" ]
        else [ :canon, "mes-ecritures" ]
        end
        Row.new(title: t("#{name}.empty_title"), detail: t("#{name}.empty_detail"), meta: t("actions.explore"),
          path: library_section_path(section, anchor:), progress: nil, icon:, avatars: [])
      end

      def library_section_path(section, anchor:, **options)
        @routes.scripture_library_path(
          **options, section:, locale: @locale, preview: (@preview ? 1 : nil), anchor:
        )
      end

      def localized_cite(source_cite, reference)
        return source_cite.presence || reference&.citation unless reference

        verse = source_cite.to_s[/:(\d+(?:[-–]\d+)?)/, 1]
        [ "#{reference.book_label} #{reference.chapter}", verse ].compact.join(":").tr("-", "–")
      end

      def preview_result
        row = ->(title, detail, meta, path, progress, icon, avatars = []) {
          Row.new(title:, detail:, meta:, path:, progress:, icon:, avatars:)
        }
        Result.new(
          quote: t("hero.preview_quote"),
          resume: row.call("Psaume 49", t("preview.resume_detail"), t("actions.continue"), @routes.scripture_path("ot/ps/49", cite: "Psaume 49:17", locale: @locale), 17.0 / 21, "scripture-book"),
          recommendation: row.call("1 Néphi 5:1", t("preview.recommendation_detail"), t("actions.read"), @routes.scripture_path("bofm/1-ne/5", cite: "1 Néphi 5:1", locale: @locale), nil, "sparkle"),
          weekly: row.call(t("preview.weekly_title"), "Psaumes 49–51 ; 61–66…", t("actions.open"), library_section_path(:weekly, anchor: "cette-semaine", unit: "preview"), 7.0 / 12, "calendar"),
          bookmarks: row.call(t("bookmarks.count", count: 4), t("preview.bookmarks_detail"), t("actions.find"), library_section_path(:bookmarks, anchor: "mes-signets"), nil, "bookmark"),
          collection: row.call(t("collections.old_testament"), t("collection.progress", count: 2), t("actions.explore"), library_section_path(:canon, anchor: "mes-ecritures", collection: :old_testament), nil, "book"),
          rama: preview_rama_row(row),
          annual: row.call(t("preview.annual_title"), t("preview.annual_detail"), t("actions.see_year"), library_section_path(:program, anchor: "programme-annuel", unit: "preview"), 34.0 / 52, "calendar")
        )
      end

      def preview_rama_row(row)
        path = @routes.scripture_circle_path(locale: @locale) if @person&.ward&.scripture_circle_readable?
        row.call(
          t("rama.reading_together", count: 7),
          path ? t("rama.detail") : t("rama.unavailable"),
          path ? t("actions.join") : t("rama.unavailable_action"),
          path, nil, "people", Array(@person&.ward&.people&.limit(4))
        )
      end
  end
end
