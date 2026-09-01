module Expeditions
  # Player-facing projection of one published expedition. The quiz catalog
  # remains the source of truth for packs; the study publication contributes
  # only selection, dates and the Council's editorial presentation.
  class Presentation
    Pack = Data.define(
      :id, :title, :kicker, :lede, :hook, :question_count, :state, :stars,
      :open_run_id, :artwork
    )

    Result = Data.define(
      :id, :study_unit, :title, :subtitle, :promise, :artwork, :packs,
      :completed_count, :total_count, :progress_percent, :state, :starts_on,
      :ends_on, :duration_days, :days_remaining
    ) do
      def study_unit_id = study_unit.id
      def pack_ids = packs.map(&:id)
      def includes_pack?(pack_id) = pack_ids.include?(pack_id.to_s)
    end

    def self.call(quiz:, world: nil, person: nil, locale: I18n.locale, at: Time.current)
      new(quiz:, world:, person:, locale:, at:).call
    end

    def initialize(quiz:, world:, person:, locale:, at:)
      @quiz = quiz
      @unit = quiz.study_unit
      @world = world
      @person = person
      @locale = Locale.i18n(locale).to_s
      @at = at
      @data = quiz.expedition
      @catalog = QuizDefinition.catalog
    end

    def call
      return unless @quiz.expedition?

      pack_ids = @quiz.expedition_pack_ids
      packs = pack_ids.filter_map { |pack_id| build_pack(pack_id) }
      # One untranslated door would make the whole expedition feel partially
      # localized. Fail closed instead of silently borrowing the global
      # Spanish fallback or rendering an incomplete constellation.
      return unless packs.size == pack_ids.size
      title = localized("title")
      return unless title

      completed = packs.count { |pack| pack.state == :finished }
      Result.new(
        id: @data["id"].presence || "study-unit-#{@unit.id}",
        study_unit: @unit,
        title:,
        subtitle: localized("subtitle"),
        promise: localized("promise"),
        artwork: @data["artwork"].presence || @quiz.content["artwork"].to_s,
        packs:,
        completed_count: completed,
        total_count: packs.size,
        progress_percent: (completed.fdiv(packs.size) * 100).round,
        state: date_state,
        starts_on: @unit.starts_on,
        ends_on: @unit.ends_on,
        duration_days: duration_days,
        days_remaining: days_remaining
      )
    rescue QuizDefinition::Error
      nil
    end

    private

      def build_pack(pack_id)
        definition = @catalog.find_pack(pack_id)
        view = Array(@world&.packs).find { |candidate| candidate.id == pack_id }
        state, stars, open_run_id = progress_for(pack_id, view)
        metadata = Array(@data["packs"]).find { |row| row["id"].to_s == pack_id } || {}
        title = localized_pack_copy(pack_id, metadata, definition, "title")
        kicker = localized_pack_copy(pack_id, metadata, definition, "kicker")
        lede = localized_pack_copy(pack_id, metadata, definition, "lede")
        hook = localized_pack_copy(pack_id, metadata, definition, "hook")
        return unless title && kicker && (lede || hook)

        Pack.new(
          id: pack_id,
          title:,
          kicker:,
          lede:,
          hook:,
          question_count: definition.questions.size,
          state:,
          stars:,
          open_run_id:,
          artwork: definition.questions.first&.presentation&.fetch("image", nil)
        )
      end

      # Expedition doors are freely selectable. A locked state in the complete
      # journey must not leak into this projection, while finished/open states
      # remain shared because the underlying permanent pack is the same.
      def progress_for(pack_id, view)
        return [ view.state == :finished ? :finished : (view.open_run_id ? :open : :available), view.stars, view.open_run_id ] if view
        return [ :available, 0, nil ] unless @person

        runs = QuizRun.street.where(person_id: @person.id, pack_id:)
        open = runs.open_runs.order(:id).last
        return [ :open, 0, open.id ] if open

        best = runs.finished.order(score: :desc, id: :desc).first
        [ best ? :finished : :available, best ? Quizzes::Stars.call(score: best.score) : 0, nil ]
      end

      def localized(key)
        localized_from(@data, key)
      end

      def localized_pack_copy(pack_id, metadata, definition, key)
        localized_from(metadata, key).presence ||
          exact_public_pack_copy(pack_id, key) ||
          authored_pack_copy(definition, key)
      end

      def exact_public_pack_copy(pack_id, key)
        i18n_key = "expedition_pack_presentations.#{pack_id}.#{key}"
        return unless I18n.exists?(i18n_key, @locale, fallback: false)

        I18n.t(i18n_key, locale: @locale, fallback: false).to_s.presence
      end

      def authored_pack_copy(definition, key)
        return unless @locale == @quiz.editorial_locale.to_s
        return unless %w[title kicker lede].include?(key)

        definition.public_send(key).to_s.presence
      end

      def localized_from(source, key)
        value = source[key]
        return value[@locale].presence if value.is_a?(Hash)
        return unless @locale == @quiz.editorial_locale.to_s

        value.to_s.presence
      end

      def date_state
        date = @at.to_date
        return :upcoming if @unit.starts_on && date < @unit.starts_on
        return :past if @unit.ends_on && date > @unit.ends_on

        :active
      end

      def duration_days
        if @unit.starts_on && @unit.ends_on
          return (@unit.ends_on - @unit.starts_on).to_i + 1
        end

        configured = @data["duration_days"].to_i
        configured.positive? ? configured : nil
      end

      def days_remaining
        return unless @unit.ends_on
        return 0 if @unit.ends_on < @at.to_date

        (@unit.ends_on - @at.to_date).to_i + 1
      end
  end
end
