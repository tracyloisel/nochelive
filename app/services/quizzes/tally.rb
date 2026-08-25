module Quizzes
  class Tally
    Row = Struct.new(:key, :label, :count, :percent, :correct, keyword_init: true)

    def self.call(pack_id:, question_id:)
      new(pack_id:, question_id:).call
    end

    def initialize(pack_id:, question_id:)
      @pack_id = pack_id
      @question_id = question_id.to_s
    end

    def call
      question = QuizDefinition.catalog.find_question(@pack_id, @question_id)
      first_ids = QuizAnswer.where(pack_id: @pack_id, question_id: @question_id)
                            .group(:device_digest).minimum(:id).values
      answers = QuizAnswer.where(id: first_ids)
      total = answers.size
      expected = question.correct_choice.to_s

      question.choices.map do |choice|
        key = (choice["key"] || choice[:key]).to_s
        count = answers.count { |answer| answer.choice_key.to_s == key }
        percent = total.zero? ? 0 : ((count * 100.0) / total).round
        Row.new(key:, label: choice["label"], count:, percent:, correct: key == expected)
      end
    end
  end
end
