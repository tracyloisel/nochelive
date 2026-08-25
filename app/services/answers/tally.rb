module Answers
  class Tally
    Row = Struct.new(:key, :label, :count, :percent, :correct, keyword_init: true)

    def self.call(round:)
      new(round:).call
    end

    def initialize(round:)
      @round = round
    end

    def call
      answers = @round.answers.to_a
      total = answers.size
      expected = expected_key

      Array(@round.definition.choices).map do |choice|
        key = key_for(choice)
        count = answers.count { |answer| answer.body.to_s == key }
        percent = total.zero? ? 0 : ((count * 100.0) / total).round
        Row.new(key:, label: label_for(choice), count:, percent:, correct: key == expected)
      end
    end

    private

    def expected_key
      @round.definition.correct_choice.to_s
    end

    def key_for(choice)
      if choice.is_a?(Hash)
        (choice["key"] || choice[:key] || choice["label"] || choice[:label]).to_s
      else
        choice.to_s
      end
    end

    def label_for(choice)
      if choice.is_a?(Hash)
        (choice["label"] || choice[:label] || choice["key"] || choice[:key]).to_s
      else
        choice.to_s
      end
    end
  end
end
