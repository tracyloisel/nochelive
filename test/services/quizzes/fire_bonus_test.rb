require "test_helper"

class Quizzes::FireBonusTest < ActiveSupport::TestCase
  setup do
    @run = Quizzes::Draw.call(device_digest: GameSession.digest_token("fire-bonus")).run
  end

  test "three hits secure the first fire and each next pair secures another" do
    answer_pattern(true, true, true, true, true, true, true, true, true, true)

    result = Quizzes::FireBonus.call(run: @run.reload)

    assert_equal QuizDefinition::CURVE_POINTS.sum, result.base_score
    assert_equal 4, result.fire_count
    assert_equal 20, result.percent
    assert_equal 21, result.bonus
    assert_equal 124, result.total_score
  end

  test "a miss breaks the live streak but keeps fires already secured" do
    answer_pattern(true, true, true, false, true, true, true, false, true, false)

    result = Quizzes::FireBonus.call(run: @run.reload)

    assert_equal 2, result.fire_count
    assert_equal 10, result.percent
    assert_equal (result.base_score * 0.10).round, result.bonus
  end

  test "fires are capped at five" do
    service = Quizzes::FireBonus.new(run: @run)
    service.define_singleton_method(:streak_lengths) { [ 13 ] }

    assert_equal 5, service.call.fire_count
    assert_equal 25, service.call.percent
  end

  private

    def answer_pattern(*verdicts)
      verdicts.each_with_index do |correct, index|
        question = @run.reload.question
        choice = if correct
          question.correct_choice
        else
          (question.choices.map { |row| row["key"] } - [ question.correct_choice ]).first
        end
        Quizzes::Submit.call(run: @run, choice_key: choice)
        Quizzes::Advance.call(run: @run.reload) unless index == verdicts.length - 1
      end
    end
end
