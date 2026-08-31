require "test_helper"

class DailyEditorialPublicationCoordinatorJobTest < ActiveJob::TestCase
  test "uses the maintenance queue" do
    assert_equal "maintenance", DailyEditorialPublicationCoordinatorJob.new.queue_name
  end

  test "surfaces a due schedule failure instead of silently losing the week" do
    failure = Studies::PublishScheduledDailyEditorials::Result.new(
      schedule_id: "library-broken",
      path: "/tmp/library-broken.yml",
      workflow_state: "scheduled",
      phase: :scheduled,
      database_state: :error,
      quiz_version_id: nil,
      message: "digest mismatch"
    )

    original = Studies::PublishScheduledDailyEditorials.method(:call)
    Studies::PublishScheduledDailyEditorials.define_singleton_method(:call) { |**| [ failure ] }
    begin
      error = assert_raises(Studies::PublishScheduledDailyEditorials::Error) do
        DailyEditorialPublicationCoordinatorJob.perform_now(at: Time.current)
      end
      assert_includes error.message, "digest mismatch"
    ensure
      Studies::PublishScheduledDailyEditorials.define_singleton_method(:call, original)
    end
  end
end
