module Quizzes
  class FireBonus
    FIRST_FIRE_AT = 3
    HITS_PER_EXTRA_FIRE = 2
    MAX_FIRES = 5
    PERCENT_PER_FIRE = 5

    Result = Struct.new(:base_score, :fire_count, :percent, :bonus, :total_score, keyword_init: true)

    def self.call(run:)
      new(run:).call
    end

    def initialize(run:)
      @run = run
    end

    def call
      base_score = @run.score.to_i
      fire_count = [ earned_fires, MAX_FIRES ].min
      percent = fire_count * PERCENT_PER_FIRE
      bonus = (base_score * percent / 100.0).round
      Result.new(base_score:, fire_count:, percent:, bonus:, total_score: base_score + bonus)
    end

    private

      def earned_fires
        streak_lengths.sum do |length|
          next 0 if length < FIRST_FIRE_AT

          1 + ((length - FIRST_FIRE_AT) / HITS_PER_EXTRA_FIRE)
        end
      end

      def streak_lengths
        answers = @run.quiz_answers.index_by(&:question_id)
        lengths = []
        current = 0

        @run.pack.questions.each do |question|
          if answers[question.id]&.correct?
            current += 1
          elsif current.positive?
            lengths << current
            current = 0
          end
        end
        lengths << current if current.positive?
        lengths
      end
  end
end
