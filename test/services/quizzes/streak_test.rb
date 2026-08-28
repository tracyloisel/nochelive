require "test_helper"

class Quizzes::StreakTest < ActiveSupport::TestCase
  test "counts distinct activity days in one aggregate query" do
    digest = GameSession.digest_token("streak-query-budget")
    travel_to Time.zone.local(2026, 8, 28, 12) do
      [ 1, 2, 4 ].each do |days_ago|
        QuizRun.create!(
          device_digest: digest,
          pack_id: "coronas",
          position: 1,
          score: 0,
          status: "finished",
          opened_at: days_ago.days.ago
        )
      end
      run = QuizRun.create!(
        device_digest: digest,
        pack_id: "coronas",
        position: 1,
        score: 0,
        status: "finished",
        opened_at: 2.days.ago
      )
      run.quiz_answers.create!(
        device_digest: digest,
        pack_id: run.pack_id,
        question_id: "streak-today",
        choice_key: "a",
        correct: true,
        created_at: Time.current
      )

      result = nil
      assert_operator sql_queries { result = Quizzes::Streak.call(device_digest: digest) }, :<=, 1
      assert_equal 3, result.days
    end
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
