module ScriptureLibraries
  # Projects one real, completed quiz answer into a factual Library prompt.
  # The service deliberately does not infer hesitation, confusion, or intent:
  # the only personal claim it exposes is the choice the person actually made.
  class QuizPrompt
    CANDIDATE_LIMIT = 50

    Result = Data.define(
      :pack_id,
      :question_id,
      :question,
      :choice_key,
      :selected_answer,
      :correct_answer,
      :correct,
      :explanation,
      :study,
      :cite,
      :path,
      :duration_ms,
      :answered_at
    ) do
      def correct? = correct
    end

    def self.call(person:, locale: I18n.locale)
      return unless person

      new(person:, locale:).call
    end

    def initialize(person:, locale:)
      @person = person
      @locale = Locale.i18n(locale)
      @routes = Rails.application.routes.url_helpers
      @catalog = QuizDefinition.catalog
    end

    def call
      latest_answers.each do |answer|
        prompt = prompt_for(answer)
        return prompt if prompt
      end

      nil
    end

    private

      def latest_answers
        QuizAnswer
          .joins(:quiz_run)
          .where(quiz_runs: { person_id: @person.id, status: "finished" })
          .order(created_at: :desc, id: :desc)
          .limit(CANDIDATE_LIMIT)
      end

      def prompt_for(answer)
        return if answer.choice_key.blank?

        definition = @catalog.find_question(answer.pack_id, answer.question_id)
        selected_choice = definition.choices.find do |choice|
          choice_key(choice) == answer.choice_key.to_s
        end
        return unless selected_choice

        reference = Scriptures::Reference.from_study(
          study: definition.scripture.study,
          locale: @locale,
          verse: 1
        )
        return unless reference

        I18n.with_locale(@locale) do
          cite = localized_cite(definition.scripture.cite, reference)
          Result.new(
            pack_id: answer.pack_id,
            question_id: answer.question_id,
            question: definition.copy(:question),
            choice_key: answer.choice_key,
            selected_answer: definition.choice_copy(selected_choice),
            correct_answer: definition.choice_copy(definition.correct_choice),
            correct: answer.correct,
            explanation: definition.copy(:answer),
            study: definition.scripture.study,
            cite:,
            path: @routes.scripture_path(definition.scripture.study, cite:, locale: @locale),
            duration_ms: answer.duration_ms,
            answered_at: answer.created_at
          )
        end
      rescue QuizDefinition::Error
        nil
      end

      def choice_key(choice)
        return choice.to_s unless choice.is_a?(Hash)

        (choice["key"] || choice[:key]).to_s
      end

      def localized_cite(source_cite, reference)
        verse = source_cite.to_s[/:(\d+(?:[-–]\d+)?)/, 1]
        [ "#{reference.book_label} #{reference.chapter}", verse ].compact.join(":").tr("-", "–")
      end
  end
end
