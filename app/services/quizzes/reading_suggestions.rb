module Quizzes
  class ReadingSuggestions
    Suggestion = Struct.new(:pack_id, :question_id, :cite, :study, keyword_init: true)

    LIMIT = 2

    def self.call(person:, limit: LIMIT)
      return [] unless person

      new(person:, limit:).call
    end

    def initialize(person:, limit:)
      @person = person
      @limit = limit
    end

    def call
      latest = QuizAnswer.joins(:quiz_run)
        .where(quiz_runs: { person_id: @person.id, status: "finished" })
        .select("DISTINCT ON (quiz_answers.pack_id, quiz_answers.question_id) quiz_answers.id")
        .order("quiz_answers.pack_id, quiz_answers.question_id, quiz_answers.created_at DESC, quiz_answers.id DESC")

      QuizAnswer.where(id: latest).where(correct: false).order(created_at: :desc, id: :desc)
        .each_with_object([]) do |answer, suggestions|
          question = QuizDefinition.catalog.find_question(answer.pack_id, answer.question_id)
          next if suggestions.any? { |item| item.study == question.scripture.study }

          suggestions << Suggestion.new(
            pack_id: answer.pack_id,
            question_id: answer.question_id,
            cite: question.scripture.cite,
            study: question.scripture.study
          )
          break suggestions if suggestions.size >= @limit
        rescue QuizDefinition::Error
          next
        end
    end
  end
end
