module Answers
  class Submit
    def self.call(round:, team:, player:, body:)
      new(round:, team:, player:, body:).call
    end

    def initialize(round:, team:, player:, body:)
      @round = round
      @team = team
      @player = player
      @body = body.to_s.strip
    end

    def call
      answer = persist!
      grade!(answer)
      pulse = { kind: pulse_kind, player: @player } if answer.previously_new_record?
      @round.game_session.broadcast_state(pulse: pulse)
      answer
    end

    private

    def persist!
      raise "Answers are closed" unless @round.accepting_answers?

      ApplicationRecord.transaction do
        locked = RoundRun.lock.find(@round.id)
        raise "Answers are closed" unless locked.accepting_answers?

        existing = Answer.find_by(round_run: locked, team: @team)
        return existing if existing

        if locked.definition.buzzer? && locked.answering_team && locked.answering_team != @team
          raise "Not your turn"
        end

        Answer.create!(round_run: locked, team: @team, player: @player, body: @body)
      end
    end

    def grade!(answer)
      return unless answer
      return unless should_grade?

      definition = @round.definition
      correct = if definition.taboo?
        definition.matches_guess?(answer.body)
      elsif definition.ordering?
        definition.matches_order?(answer.body)
      elsif definition.category?
        definition.matching_names(answer.body).size >= definition.category_goal
      elsif definition.mime?
        definition.matches_path?(answer.body)
      else
        expected = if @player.remote? && definition.variant_correct.present?
          definition.variant_correct
        else
          definition.correct_choice
        end
        answer.body.to_s == expected.to_s
      end

      return if (definition.taboo? || definition.category?) && !correct

      if correct
        Scores::Apply.correct!(@round, @team, broadcast: false)
      else
        Scores::Apply.incorrect!(@round, @team, broadcast: false)
      end
    end

    def pulse_kind
      definition = @round.definition
      return "found" if definition.scavenger?
      return "shout" if definition.category?

      "answer"
    end

    def should_grade?
      definition = @round.definition
      definition.choice? || definition.taboo? || definition.ordering? ||
        (definition.category? && @player.remote?) ||
        (@player.remote? && definition.mime?)
    end
  end
end
