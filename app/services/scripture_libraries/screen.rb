module ScriptureLibraries
  # Read model for the Library's editorial stream. Personal sections are nil
  # when their underlying fact does not exist; only recovery tools are always
  # projected, because they remain useful even with a zero count.
  class Screen
    Editorial = Data.define(
      :id, :kind, :scheduled_on, :time_zone, :locale, :reference, :claim_ids,
      :eyebrow, :title, :setup, :question, :cta_label, :artwork_key,
      :light_family, :depiction_mode, :certainty, :disclosure, :alt, :motion,
      :audio, :cite, :path
    )

    Resume = Data.define(
      :reference, :cite, :title, :detail, :path, :last_verse, :progress
    )

    Week = Data.define(
      :id, :title, :period, :corpus, :starts_on, :ends_on, :path,
      :reading_completed_count, :reading_total_count, :reading_progress,
      :expedition_title, :expedition_promise, :expedition_path,
      :expedition_completed_count, :expedition_total_count, :expedition_progress
    )

    Tool = Data.define(:kind, :title, :detail, :path, :count, :progress, :icon)

    Tools = Data.define(:bookmarks, :scriptures, :annual) do
      # Transitional name used by the old row-based view.
      def collection = scriptures
    end

    Result = Data.define(:editorial, :resume, :week, :quiz_prompt, :rama_highlights, :tools) do
      # Transitional read aliases. New Library partials consume the six fields
      # above directly; keeping these names makes rollout failures easier to
      # diagnose while the old row view is being removed in a separate lot.
      def recommendation = quiz_prompt
      def weekly = week
      def expedition
        week if week&.expedition_title.present?
      end
      def bookmarks = tools.bookmarks
      def collection = tools.scriptures
      def rama = rama_highlights
      def annual = tools.annual
      def quote = editorial&.question.presence || editorial&.setup
    end

    COLLECTIONS = {
      old_testament: "ot/",
      new_testament: "nt/",
      book_of_mormon: "bofm/",
      doctrine_and_covenants: "dc-testament/"
    }.freeze

    def self.call(person:, locale:, on: nil, at: Time.current, time_zone: nil, preview: false)
      new(person:, locale:, on:, at:, time_zone:, preview:).call
    end

    def initialize(person:, locale:, on:, at:, time_zone:, preview:)
      @person = person
      @locale = Locale.i18n(locale)
      @requested_time_zone = time_zone.presence
      @requested_on = on&.to_date
      @input_at = at
      @preview = preview
      @routes = Rails.application.routes.url_helpers
    end

    def call
      load_week_context
      return preview_result if @preview

      editorial = editorial_discovery
      references = weekly_studies
      references << editorial.reference if editorial&.reference.present?

      Result.new(
        editorial:,
        resume: resume,
        week: week,
        quiz_prompt: QuizPrompt.call(person: @person, locale: @locale),
        rama_highlights: ScriptureCircles::LibraryHighlights.call(
          person: @person,
          locale: @locale,
          references: references.uniq,
          at: @at
        ),
        tools: tools
      )
    end

    private

      def load_week_context
        identity_time_zone = @requested_time_zone || @person&.ward&.time_zone.presence
        @program = StudyProgram.where(status: "published").order(year: :desc).first

        if identity_time_zone.present?
          resolve_clock(identity_time_zone)
          load_week_and_quiz
        elsif (context = editorial_week_context)
          @study_week, @quiz, editorial_time_zone = context
          resolve_clock(editorial_time_zone)
        else
          # Time.zone is only a non-editorial calendar fallback. It is never
          # sent to DailyDiscovery as though it were an approved schedule zone.
          resolve_clock(nil)
          load_week_and_quiz
        end

        @expedition = if @quiz&.expedition?
          Expeditions::Presentation.call(quiz: @quiz, person: @person, locale: @locale, at: @at)
        end
      end

      def resolve_clock(time_zone)
        @time_zone = time_zone.presence
        @zone = @time_zone ? Time.find_zone!(@time_zone) : Time.zone
        @at = if @requested_on
          @zone.local(@requested_on.year, @requested_on.month, @requested_on.day, 12)
        else
          @input_at
        end
        @on = @at.in_time_zone(@zone).to_date
      end

      def load_week_and_quiz
        @study_week = @program&.current_week(on: @on)
        @quiz = @study_week&.published_quiz
      end

      # A guest has no ward clock. Around midnight, selecting a week in the
      # server zone first can choose Sunday while the approved editorial clock
      # is already Monday. Resolve the candidate quiz and its explicit clock
      # together from the only dates any global timezone can currently see.
      def editorial_week_context
        return unless @program

        range = editorial_candidate_dates
        candidates = @program.study_units.weeks
          .where(status: "published")
          .where("starts_on <= ? AND ends_on >= ?", range.end, range.begin)
          .includes(:study_quiz_versions)
          .filter_map do |candidate_week|
            candidate_quiz = candidate_week.published_quiz
            zone_name = candidate_quiz&.daily_discovery_time_zone
            zone = Time.find_zone(zone_name)
            next unless zone

            local_date = @requested_on || @input_at.in_time_zone(zone).to_date
            next unless local_date.between?(candidate_week.starts_on, candidate_week.ends_on)

            [ candidate_week, candidate_quiz, zone.name ]
          end

        candidates.one? ? candidates.first : nil
      end

      def editorial_candidate_dates
        return @requested_on..@requested_on if @requested_on

        utc_date = @input_at.to_time.utc.to_date
        (utc_date - 1.day)..(utc_date + 1.day)
      end

      def t(key, **options)
        I18n.t("scripture_library.#{key}", locale: @locale, **options)
      end

      def editorial_discovery
        return unless @quiz
        return unless @time_zone
        return unless defined?(Expeditions::DailyDiscovery)

        discovery = Expeditions::DailyDiscovery.call(
          quiz: @quiz,
          locale: @locale,
          at: @at,
          time_zone: @time_zone
        )
        return unless discovery

        reference = Scriptures::Reference.from_study(study: discovery.reference, locale: @locale, verse: 1)
        return unless reference

        cite = "#{reference.book_label} #{reference.chapter}"
        Editorial.new(
          id: discovery.id,
          kind: discovery.kind,
          scheduled_on: discovery.scheduled_on,
          time_zone: discovery.time_zone,
          locale: discovery.locale,
          reference: discovery.reference,
          claim_ids: discovery.claim_ids,
          eyebrow: discovery.eyebrow,
          title: discovery.title,
          setup: discovery.setup,
          question: discovery.question,
          cta_label: discovery.cta_label,
          artwork_key: discovery.artwork_key,
          light_family: discovery.light_family,
          depiction_mode: discovery.depiction_mode,
          certainty: discovery.certainty,
          disclosure: discovery.disclosure,
          alt: discovery.alt,
          motion: discovery.motion,
          audio: discovery.audio,
          cite:,
          path: @routes.scripture_path(discovery.reference, cite:, locale: @locale)
        )
      end

      def resume
        return unless @person

        progress = @person.scripture_reading_progresses
          .where(locale: @locale.to_s, completed_at: nil)
          .where("progress_ratio >= ?", 0.08)
          .order(last_opened_at: :desc, id: :desc)
          .first
        return unless progress

        reference = Scriptures::Reference.from_study(
          study: progress.reference,
          locale: @locale,
          verse: progress.last_verse
        )
        return unless reference

        percent = (progress.progress_ratio.to_f * 100).round
        Resume.new(
          reference: progress.reference,
          cite: reference.citation,
          title: reference.citation,
          detail: t("resume.progress", verse: progress.last_verse, percent:),
          path: @routes.scripture_path(
            progress.reference,
            cite: reference.citation,
            locale: @locale
          ),
          last_verse: progress.last_verse,
          progress: progress.progress_ratio.to_f
        )
      end

      def week
        readings = weekly_readings
        return unless @study_week && (readings.any? || @expedition)

        studies = readings.map { |reading| reading.fetch("study") }
        reading_total = studies.size
        reading_completed = completed_reading_count(studies)
        Week.new(
          id: @study_week.id,
          title: @study_week.theme(@locale),
          period: @study_week.display_period(@locale),
          corpus: @study_week.display_scripture_refs(@locale).join(" ; "),
          starts_on: @study_week.starts_on,
          ends_on: @study_week.ends_on,
          path: library_section_path(:weekly, anchor: "cette-semaine", unit: @study_week.id),
          reading_completed_count: reading_completed,
          reading_total_count: reading_total,
          reading_progress: ratio_including_zero(reading_completed, reading_total),
          expedition_title: @expedition&.title,
          expedition_promise: @expedition&.promise,
          expedition_path: expedition_path,
          expedition_completed_count: @expedition&.completed_count,
          expedition_total_count: @expedition&.total_count,
          expedition_progress: ratio_including_zero(
            @expedition&.completed_count,
            @expedition&.total_count
          )
        )
      end

      def weekly_readings
        @weekly_readings ||= Array(@quiz&.readings(@locale)).filter_map do |reading|
          study = reading["study"].to_s
          next unless Scriptures::Reference.known_study?(study)

          reading.merge("study" => study)
        end.uniq { |reading| reading.fetch("study") }
      end

      def weekly_studies
        weekly_readings.map { |reading| reading.fetch("study") }
      end

      def completed_reading_count(studies)
        return 0 unless @person && studies.any?

        @person.scripture_reading_progresses
          .where(locale: @locale.to_s, reference: studies)
          .where.not(completed_at: nil)
          .count
      end

      def expedition_path
        return unless @expedition

        @routes.street_map_path(view: "expeditions", expedition: @expedition.study_unit_id)
      end

      def tools
        Tools.new(
          bookmarks: bookmarks_tool,
          scriptures: scriptures_tool,
          annual: annual_tool
        )
      end

      def bookmarks_tool
        marks = @person ? @person.scripture_marks.active.where.not(bookmarked_at: nil) : ScriptureMark.none
        count = marks.count
        return unless count.positive?

        last = marks.order(bookmarked_at: :desc, id: :desc).first
        detail = if last
          reference = Scriptures::Reference.from_study(
            study: last.reference,
            locale: @locale,
            verse: last.start_verse || 1
          )
          text = last.note_body.presence || last.selected_text.presence
          [ reference&.citation, text&.truncate(56) ].compact.join(" — ")
        else
          t("bookmarks.empty")
        end

        Tool.new(
          kind: :bookmarks,
          title: t("bookmarks.count", count:),
          detail:,
          path: library_section_path(:bookmarks, anchor: "mes-signets"),
          count:,
          progress: nil,
          icon: "bookmark"
        )
      end

      def scriptures_tool
        references = if @person
          (
            @person.scripture_chapter_reads.distinct.pluck(:reference) +
            @person.scripture_marks.active.distinct.pluck(:reference)
          ).uniq
        else
          []
        end
        key, count = COLLECTIONS
          .map { |name, prefix| [ name, references.count { |reference| reference.start_with?(prefix) } ] }
          .max_by(&:last)
        key ||= :old_testament

        Tool.new(
          kind: :scriptures,
          title: t("collections.#{key}"),
          detail: t("collection.progress", count:),
          path: library_section_path(:canon, anchor: "mes-ecritures", collection: key),
          count:,
          progress: nil,
          icon: "book"
        )
      end

      def annual_tool
        return unless @program

        weeks = @program.study_units.weeks.to_a
        return if weeks.empty?

        current = @study_week || weeks.min_by { |unit| ((unit.starts_on || @on) - @on).abs }
        return unless current

        index = weeks.index(current).to_i + 1
        Tool.new(
          kind: :annual,
          title: t("annual.week", number: index, heading: current.display_heading(@locale)),
          detail: current.display_period(@locale),
          path: library_section_path(:program, anchor: "programme-annuel", unit: current.id),
          count: weeks.size,
          progress: index.fdiv([ weeks.size, 1 ].max),
          icon: "calendar"
        )
      end

      def ratio_including_zero(numerator, denominator)
        return unless denominator.to_i.positive?

        numerator.to_i.fdiv(denominator.to_i).clamp(0.0, 1.0)
      end

      def library_section_path(section, anchor:, **options)
        @routes.scripture_library_path(
          **options,
          section:,
          locale: @locale,
          preview: (@preview ? 1 : nil),
          anchor:
        )
      end

      def preview_result
        Result.new(
          editorial: preview_editorial,
          resume: Resume.new(
            reference: "ot/ps/119",
            cite: preview_citation("ot/ps/119", verse: 72),
            title: preview_citation("ot/ps/119"),
            detail: t("editorial.preview.resume_detail"),
            path: @routes.scripture_path(
              "ot/ps/119",
              cite: preview_citation("ot/ps/119", verse: 72),
              locale: @locale
            ),
            last_verse: 72,
            progress: 72.0 / 176
          ),
          week: preview_week,
          quiz_prompt: preview_quiz_prompt,
          rama_highlights: preview_rama_highlights,
          tools: preview_tools
        )
      end

      def preview_editorial
        cite = preview_citation("ot/ps/137")
        Editorial.new(
          id: "preview-ps137-suspended-harps",
          kind: "discovery",
          scheduled_on: @on,
          time_zone: @time_zone || @zone.name,
          locale: @locale.to_s,
          reference: "ot/ps/137",
          claim_ids: %w[ps137-jerusalem-destroyed ps137-harps-suspended],
          eyebrow: t("editorial.preview.eyebrow"),
          title: t("editorial.preview.title"),
          setup: t("editorial.preview.setup"),
          question: t("editorial.preview.question"),
          cta_label: t("editorial.preview.cta"),
          artwork_key: "scripture.library.daily.ps137.suspended-harps",
          light_family: "dark",
          depiction_mode: "symbolic",
          certainty: "textual_scene_with_unidentified_setting",
          disclosure: t("editorial.preview.disclosure"),
          alt: t("editorial.preview.alt"),
          motion: "still",
          audio: "silent",
          cite:,
          path: @routes.scripture_path("ot/ps/137", cite:, locale: @locale)
        )
      end

      # Preview data is reachable only through the local-environment gate in
      # the controller. Production always uses real answers and safe Circle
      # projections from #call.
      def preview_quiz_prompt
        cite = preview_citation("ot/ps/110")
        QuizPrompt::Result.new(
          pack_id: "preview-psalms",
          question_id: "preview-melchizedek",
          question: t("editorial.preview.quiz_question"),
          choice_key: "melchizedek",
          selected_answer: t("editorial.preview.melchizedek"),
          correct_answer: t("editorial.preview.melchizedek"),
          correct: true,
          explanation: t("editorial.preview.quiz_explanation"),
          study: "ot/ps/110",
          cite:,
          path: @routes.scripture_path("ot/ps/110", cite:, locale: @locale),
          duration_ms: 4_800,
          answered_at: @at - 1.hour
        )
      end

      def preview_rama_highlights
        [
          preview_highlight(
            id: "preview-ps102",
            author_name: "Carmen",
            avatar_key: "colibri",
            study: "ot/ps/102",
            body: t("editorial.preview.rama_first"),
            reply_count: 3,
            created_at: @at - 2.hours
          ),
          preview_highlight(
            id: "preview-ps110",
            author_name: "Jean-Marc",
            avatar_key: "delfin",
            study: "ot/ps/110",
            body: t("editorial.preview.rama_second"),
            reply_count: 0,
            created_at: @at - 3.hours
          )
        ].freeze
      end

      def preview_highlight(id:, author_name:, avatar_key:, study:, body:, reply_count:, created_at:)
        citation = preview_citation(study)
        ScriptureCircles::LibraryHighlights::Highlight.new(
          id:,
          kind: "reflection",
          body:,
          selected_text: nil,
          created_at:,
          author_name:,
          avatar_key:,
          anonymous: false,
          own: false,
          reference: study,
          citation:,
          reply_count:,
          path: @routes.scripture_circle_path(locale: @locale, conversation: id),
          reader_path: @routes.scripture_path(study, cite: citation, locale: @locale)
        )
      end

      def preview_citation(study, verse: nil)
        reference = Scriptures::Reference.from_study(study:, locale: @locale, verse: verse || 1)
        return study unless reference

        verse ? reference.citation : "#{reference.book_label} #{reference.chapter}"
      end

      def preview_week
        Week.new(
          id: "preview",
          title: t("preview.weekly_title"),
          period: t("preview.annual_detail"),
          corpus: "Psaumes 102–150",
          starts_on: @on.beginning_of_week,
          ends_on: @on.end_of_week,
          path: library_section_path(:weekly, anchor: "cette-semaine", unit: "preview"),
          reading_completed_count: 7,
          reading_total_count: 12,
          reading_progress: 7.0 / 12,
          expedition_title: t("preview.expedition_title"),
          expedition_promise: t("preview.expedition_detail"),
          expedition_path: @routes.street_map_path(view: "expeditions"),
          expedition_completed_count: 2,
          expedition_total_count: 6,
          expedition_progress: 2.0 / 6
        )
      end

      def preview_tools
        Tools.new(
          bookmarks: Tool.new(
            kind: :bookmarks,
            title: t("bookmarks.count", count: 4),
            detail: t("preview.bookmarks_detail"),
            path: library_section_path(:bookmarks, anchor: "mes-signets"),
            count: 4,
            progress: nil,
            icon: "bookmark"
          ),
          scriptures: Tool.new(
            kind: :scriptures,
            title: t("collections.old_testament"),
            detail: t("collection.progress", count: 2),
            path: library_section_path(:canon, anchor: "mes-ecritures", collection: :old_testament),
            count: 2,
            progress: nil,
            icon: "book"
          ),
          annual: Tool.new(
            kind: :annual,
            title: t("preview.annual_title"),
            detail: t("preview.annual_detail"),
            path: library_section_path(:program, anchor: "programme-annuel", unit: "preview"),
            count: 52,
            progress: 34.0 / 52,
            icon: "calendar"
          )
        )
      end
  end
end
