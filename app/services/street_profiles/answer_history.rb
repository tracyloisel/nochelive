module StreetProfiles
  class AnswerHistory
    PAGE_SIZE = 8

    Result = Struct.new(
      :person, :sessions, :page, :total_pages, :total_sessions,
      :total_answers, :correct_answers, :average_duration_ms,
      keyword_init: true
    )
    Session = Struct.new(
      :id, :kind, :title, :subtitle, :played_at, :status,
      :correct_answers, :answer_count, :answers,
      keyword_init: true
    )
    Entry = Struct.new(
      :id, :position, :question, :chosen_answer, :correct_answer,
      :correct, :duration_ms, :answered_at, :scripture,
      keyword_init: true
    )
    SessionReference = Struct.new(:kind, :id, :updated_at, keyword_init: true)

    def self.call(person:, page: 1, locale: I18n.locale)
      new(person:, page:, locale:).call
    end

    def initialize(person:, page:, locale:)
      @person = person
      @requested_page = page.to_i
      @locale = Locale.i18n(locale)
    end

    def call
      references = session_references
      total_pages = [ (references.size.fdiv(PAGE_SIZE)).ceil, 1 ].max
      page = @requested_page.clamp(1, total_pages)
      visible_references = references.slice((page - 1) * PAGE_SIZE, PAGE_SIZE) || []
      totals = answer_totals

      Result.new(
        person: @person,
        sessions: load_sessions(visible_references),
        page:,
        total_pages:,
        total_sessions: references.size,
        total_answers: totals.fetch(:answers),
        correct_answers: totals.fetch(:correct),
        average_duration_ms: average_duration(totals)
      )
    end

    private

      def session_references
        adventure = adventure_runs.pluck(:id, :updated_at).map do |id, updated_at|
          SessionReference.new(kind: :adventure, id:, updated_at:)
        end
        word = word_runs.pluck(:id, :updated_at).map do |id, updated_at|
          SessionReference.new(kind: :word, id:, updated_at:)
        end

        (adventure + word).sort_by { |reference| [ reference.updated_at, reference.kind.to_s, reference.id ] }.reverse
      end

      def adventure_runs
        QuizRun.street.where(person_id: @person.id, id: QuizAnswer.select(:quiz_run_id))
      end

      def word_runs
        StudyRun.where(person_id: @person.id, id: StudyAnswer.select(:study_run_id))
      end

      def adventure_answers
        QuizAnswer.joins(:quiz_run).merge(QuizRun.street).where(quiz_runs: { person_id: @person.id })
      end

      def word_answers
        StudyAnswer.joins(:study_run).where(study_runs: { person_id: @person.id })
      end

      def answer_totals
        adventure = adventure_answers
        word = word_answers
        {
          answers: adventure.count + word.count,
          correct: adventure.where(correct: true).count + word.where(correct: true).count,
          timed: adventure.where.not(duration_ms: nil).count + word.where.not(duration_ms: nil).count,
          duration_ms: adventure.sum(:duration_ms) + word.sum(:duration_ms)
        }
      end

      def average_duration(totals)
        return if totals.fetch(:timed).zero?

        (totals.fetch(:duration_ms).fdiv(totals.fetch(:timed))).round
      end

      def load_sessions(references)
        adventure_ids = references.filter_map { |reference| reference.id if reference.kind == :adventure }
        word_ids = references.filter_map { |reference| reference.id if reference.kind == :word }
        adventures = QuizRun.street.where(id: adventure_ids).includes(:quiz_answers).index_by(&:id)
        words = StudyRun.where(id: word_ids)
          .includes(:study_answers, study_quiz_version: { study_unit: :study_program })
          .index_by(&:id)

        references.filter_map do |reference|
          if reference.kind == :adventure
            build_adventure_session(adventures[reference.id])
          else
            build_word_session(words[reference.id])
          end
        end
      end

      def build_adventure_session(run)
        return unless run

        pack = find_adventure_pack(run.pack_id)
        answers = run.quiz_answers.sort_by { |answer| adventure_position(pack, answer) }
          .map { |answer| build_adventure_entry(pack, answer) }
        Session.new(
          id: "adventure-#{run.id}",
          kind: :adventure,
          title: localized_pack_copy(pack, :title) || translate(:unknown_quiz),
          subtitle: localized_pack_copy(pack, :kicker) || translate(:adventure_source),
          played_at: answers.map(&:answered_at).compact.max || run.updated_at,
          status: run.status,
          correct_answers: answers.count(&:correct),
          answer_count: answers.size,
          answers:
        )
      end

      def build_adventure_entry(pack, answer)
        question = pack&.questions&.find { |candidate| candidate.id == answer.question_id }
        Entry.new(
          id: "adventure-answer-#{answer.id}",
          position: question&.position,
          question: localized_question_copy(question, :question) || translate(:unknown_question),
          chosen_answer: adventure_choice(question, answer.choice_key),
          correct_answer: adventure_choice(question, question&.correct_choice, unavailable: true),
          correct: answer.correct?,
          duration_ms: answer.duration_ms,
          answered_at: answer.created_at,
          scripture: question&.scripture_cite
        )
      end

      def find_adventure_pack(pack_id)
        QuizDefinition.catalog.find_pack(pack_id)
      rescue QuizDefinition::Error
        nil
      end

      def build_word_session(run)
        return unless run

        version = run.study_quiz_version
        unit = version.study_unit
        answers = run.study_answers.sort_by { |answer| word_position(version, answer) || answer.id }
          .map { |answer| build_word_entry(version, answer) }
        Session.new(
          id: "word-#{run.id}",
          kind: :word,
          title: unit.display_heading(@locale),
          subtitle: unit.study_program.display_title(@locale),
          played_at: answers.map(&:answered_at).compact.max || run.updated_at,
          status: run.status,
          correct_answers: answers.count(&:correct),
          answer_count: answers.size,
          answers:
        )
      end

      def build_word_entry(version, answer)
        position = word_position(version, answer)
        base = position ? version.question_at(position) : nil
        question = position ? version.localized_question(position, @locale) : nil
        choices = question&.fetch("choices", {}) || {}
        Entry.new(
          id: "word-answer-#{answer.id}",
          position:,
          question: question&.fetch("question", nil) || translate(:unknown_question),
          chosen_answer: choices[answer.choice_key].presence || answer.choice_key.to_s.humanize,
          correct_answer: choices[base&.fetch("correct_choice", nil)].presence || translate(:answer_unavailable),
          correct: answer.correct?,
          duration_ms: answer.duration_ms,
          answered_at: answer.created_at,
          scripture: question&.fetch("scripture_ref", nil)
        )
      end

      def adventure_position(pack, answer)
        pack&.questions&.find { |question| question.id == answer.question_id }&.position || answer.id
      end

      def word_position(version, answer)
        index = version.questions.index { |question| question["key"] == answer.question_key }
        index ? index + 1 : nil
      end

      def localized_pack_copy(pack, field)
        I18n.with_locale(@locale) { pack&.copy(field) }
      end

      def localized_question_copy(question, field)
        I18n.with_locale(@locale) { question&.copy(field) }
      end

      def adventure_choice(question, key, unavailable: false)
        return translate(:not_answered) if key.blank? && !unavailable
        return translate(:answer_unavailable) if key.blank?

        choice = question&.choices&.find { |candidate| candidate.fetch("key") == key.to_s }
        return key.to_s.humanize unless choice

        I18n.with_locale(@locale) { question.choice_copy(choice) }
      end

      def translate(key)
        I18n.t("street.quiz_history.#{key}", locale: @locale)
      end
  end
end
