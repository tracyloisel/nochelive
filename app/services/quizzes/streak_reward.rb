module Quizzes
  class StreakReward
    BASE_POINTS = 5
    MAX_BONUS_AT = 5
    MAX_BONUS = 5
    BONUS_BY_STREAK = { 1 => 0, 2 => 2, 3 => 3, 4 => 4 }.freeze

    Result = Struct.new(
      :streak_before, :streak_after,
      :base_points, :streak_bonus, :points_awarded, :bonus_lost,
      :remaining_to_max, :total_before, :total_after,
      keyword_init: true
    ) do
      def max_bonus_active? = streak_after.to_i >= Quizzes::StreakReward::MAX_BONUS_AT
    end

    Summary = Struct.new(:base_points, :streak_bonus, :total_points, :max_streak, keyword_init: true)

    def self.call(run:, correct:)
      new(run:).call(correct:)
    end

    def self.from_answer(run:, answer:)
      return unless answer

      if answer.points_awarded.nil?
        legacy_from_answer(run:, answer:)
      else
        points = answer.points_awarded.to_i
        Result.new(
          streak_before: answer.streak_before.to_i,
          streak_after: answer.streak_after.to_i,
          base_points: answer.base_points.to_i,
          streak_bonus: answer.streak_bonus.to_i,
          points_awarded: points,
          bonus_lost: answer.bonus_lost.to_i,
          remaining_to_max: [ MAX_BONUS_AT - answer.streak_after.to_i, 0 ].max,
          total_before: [ run.score.to_i - points, 0 ].max,
          total_after: run.score.to_i
        )
      end
    end

    def self.summary(run:)
      answers = ordered_answers(run)
      if answers.present? && answers.all? { |answer| !answer.points_awarded.nil? }
        Summary.new(
          base_points: answers.sum { |answer| answer.base_points.to_i },
          streak_bonus: answers.sum { |answer| answer.streak_bonus.to_i },
          total_points: answers.sum { |answer| answer.points_awarded.to_i },
          max_streak: answers.map { |answer| answer.streak_after.to_i }.max.to_i
        )
      else
        legacy_bonus = run.fire_bonus.to_i
        legacy_base = if run.base_score.to_i.positive? || legacy_bonus.positive?
          run.base_score.to_i
        else
          [ run.score.to_i - legacy_bonus, 0 ].max
        end
        Summary.new(
          base_points: legacy_base,
          streak_bonus: legacy_bonus,
          total_points: run.score.to_i,
          max_streak: HitStreak.max_count(run:)
        )
      end
    end

    def self.remaining_potential(run:)
      answers = ordered_answers(run)
      streak = answers.reverse.take_while(&:correct?).size
      remaining = [ run.pack.questions.size - answers.size, 0 ].max
      (1..remaining).sum do |offset|
        BASE_POINTS + bonus_for(streak + offset)
      end
    end

    def self.max_pack_score(question_count: QuizDefinition::QUESTIONS_PER_PACK)
      (1..question_count).sum { |streak| BASE_POINTS + bonus_for(streak) }
    end

    def self.bonus_for(streak)
      count = streak.to_i
      return MAX_BONUS if count >= MAX_BONUS_AT

      BONUS_BY_STREAK.fetch(count, 0)
    end

    def self.normalize_open_run!(run)
      return unless run.open?

      answers = ordered_answers(run)
      return if answers.all? { |answer| !answer.points_awarded.nil? }

      streak = 0
      score = 0
      answers.each do |answer|
        before = streak
        if answer.correct?
          streak += 1
          bonus = bonus_for(streak)
          base = BASE_POINTS
          awarded = base + bonus
          lost = 0
        else
          bonus = 0
          base = 0
          awarded = 0
          lost = bonus_for(before)
          streak = 0
        end
        answer.update_columns(
          base_points: base,
          streak_bonus: bonus,
          points_awarded: awarded,
          streak_before: before,
          streak_after: streak,
          bonus_lost: lost
        )
        score += awarded
      end
      run.update_columns(score: score)
    end

    def self.ordered_answers(run)
      answers = run.quiz_answers.index_by(&:question_id)
      run.pack.questions.filter_map { |question| answers[question.id] }
    end
    private_class_method :ordered_answers

    def self.legacy_from_answer(run:, answer:)
      points = answer.correct? ? run.pack.questions.find { |question| question.id == answer.question_id }&.points.to_i : 0
      Result.new(
        streak_before: 0,
        streak_after: 0,
        base_points: points,
        streak_bonus: 0,
        points_awarded: points,
        bonus_lost: 0,
        remaining_to_max: MAX_BONUS_AT,
        total_before: [ run.score.to_i - points, 0 ].max,
        total_after: run.score.to_i
      )
    end
    private_class_method :legacy_from_answer

    def initialize(run:)
      @run = run
    end

    def call(correct:)
      before = current_streak
      total_before = @run.score.to_i
      if correct
        after = before + 1
        bonus = self.class.bonus_for(after)
        base = BASE_POINTS
        awarded = base + bonus
        lost = 0
      else
        after = 0
        bonus = 0
        base = 0
        awarded = 0
        lost = self.class.bonus_for(before)
      end
      Result.new(
        streak_before: before,
        streak_after: after,
        base_points: base,
        streak_bonus: bonus,
        points_awarded: awarded,
        bonus_lost: lost,
        remaining_to_max: [ MAX_BONUS_AT - after, 0 ].max,
        total_before:,
        total_after: total_before + awarded
      )
    end

    private

      def current_streak
        self.class.send(:ordered_answers, @run).reverse.take_while(&:correct?).size
      end
  end
end
