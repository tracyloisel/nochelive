require "test_helper"

class Quizzes::TrailTest < ActiveSupport::TestCase
  setup do
    @digest = GameSession.digest_token("trail-device")
    @frame = Quizzes::Draw.call(device_digest: @digest)
    @run = @frame.run
  end

  test "starts with one pack and the first question" do
    steps = Quizzes::Trail.call(run: @run)
    assert_equal 2, steps.size
    assert steps.first.pack?
    assert steps.last.question?
    assert_equal :current, steps.last.state
  end

  test "marks answered steps on the path" do
    Quizzes::Submit.call(run: @run, choice_key: @frame.question.correct_choice)
    Quizzes::Advance.call(run: @run.reload)
    wrong = @run.pack.question_at(2)
    bad = wrong.choices.map { |choice| choice.is_a?(Hash) ? (choice["key"] || choice[:key]) : choice.to_s }.find { |key| key != wrong.correct_choice }
    Quizzes::Submit.call(run: @run.reload, choice_key: bad)

    steps = Quizzes::Trail.call(run: @run.reload)
    first = steps.find { |step| step.question? && step.position == 1 }
    second = steps.find { |step| step.question? && step.position == 2 }
    assert_equal :correct, first.state
    assert_equal :wrong, second.state
    assert first.jumpable?
    assert second.jumpable?
  end

  test "loads prior runs and answers in a constant query budget" do
    pack_ids = QuizDefinition.catalog.pack_ids.first(5)
    runs = pack_ids.map do |pack_id|
      QuizRun.create!(
        device_digest: @digest,
        pack_id:,
        position: QuizDefinition::QUESTIONS_PER_PACK,
        score: 40,
        status: "finished",
        opened_at: Time.current
      )
    end
    runs.each do |run|
      question = run.pack.question_at(1)
      run.quiz_answers.create!(
        device_digest: @digest,
        pack_id: run.pack_id,
        question_id: question.id,
        choice_key: question.correct_choice,
        correct: true
      )
    end

    assert_operator sql_queries { Quizzes::Trail.call(run: runs.last) }, :<=, 2
  end

  private

    def sql_queries(&block)
      count = 0
      callback = lambda do |_name, _start, _finish, _id, payload|
        count += 1 unless payload[:cached] || payload[:name].in?(%w[SCHEMA TRANSACTION])
      end
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &block)
      count
    end
end
