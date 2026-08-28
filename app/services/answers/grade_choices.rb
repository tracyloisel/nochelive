module Answers
  class GradeChoices
    def self.call(round:)
      new(round:).call
    end

    def initialize(round:)
      @round = round
    end

    def call
      return @round unless @round.definition.has_choices?

      @round.answers.includes(:team, :player).find_each do |answer|
        next if @round.score_events.exists?(team: answer.team, kind: %w[correct incorrect])

        if answer.body.to_s == expected_choice(answer).to_s
          Scores::Apply.correct!(@round, answer.team, broadcast: false)
        else
          Scores::Apply.incorrect!(@round, answer.team, broadcast: false)
        end
      end
      @round
    end

    private

      def expected_choice(answer)
        if answer.player&.remote? && @round.definition.variant_correct.present?
          @round.definition.variant_correct
        else
          @round.definition.correct_choice
        end
      end
  end
end
