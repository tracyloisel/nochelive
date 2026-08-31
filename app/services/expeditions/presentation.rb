module Expeditions
  # Player-facing projection of one published expedition. The quiz catalog
  # remains the source of truth for packs; the study publication contributes
  # only selection, dates and the Council's editorial presentation.
  class Presentation
    Pack = Data.define(
      :id, :definition, :title, :kicker, :lede, :hook, :experience,
      :question_count, :state, :stars, :open_run_id, :artwork
    )

    Result = Data.define(
      :id, :study_unit, :study_quiz_version, :title, :subtitle, :promise,
      :artwork, :structure_type, :packs, :completed_count, :total_count,
      :progress_percent, :reading_count, :state
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

      packs = @quiz.expedition_pack_ids.filter_map { |pack_id| build_pack(pack_id) }
      return if packs.empty?

      completed = packs.count { |pack| pack.state == :finished }
      Result.new(
        id: @data["id"].presence || "study-unit-#{@unit.id}",
        study_unit: @unit,
        study_quiz_version: @quiz,
        title: localized("title") || @unit.theme(@locale),
        subtitle: localized("subtitle"),
        promise: localized("promise"),
        artwork: @data["artwork"].presence || @quiz.content["artwork"].to_s,
        structure_type: @data["structure_type"].presence || "constellation",
        packs:,
        completed_count: completed,
        total_count: packs.size,
        progress_percent: (completed.fdiv(packs.size) * 100).round,
        reading_count: @quiz.readings(@locale).size,
        state: date_state
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

        I18n.with_locale(@locale) do
          Pack.new(
            id: pack_id,
            definition:,
            title: localized_from(metadata, "title") || definition.copy(:title),
            kicker: localized_from(metadata, "kicker") || definition.copy(:kicker),
            lede: localized_from(metadata, "lede") || definition.copy(:lede),
            hook: localized_from(metadata, "hook"),
            experience: localized_from(metadata, "experience"),
            question_count: definition.questions.size,
            state:,
            stars:,
            open_run_id:,
            artwork: definition.questions.first&.presentation&.fetch("image", nil)
          )
        end
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

      def localized_from(source, key)
        value = source[key]
        return value.to_s.presence unless value.is_a?(Hash)

        value[@locale].presence || value["fr"].presence || value.values.find(&:present?)
      end

      def date_state
        date = @at.to_date
        return :upcoming if @unit.starts_on && date < @unit.starts_on
        return :past if @unit.ends_on && date > @unit.ends_on

        :active
      end
  end
end
