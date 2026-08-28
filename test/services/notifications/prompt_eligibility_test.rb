require "test_helper"

class Notifications::PromptEligibilityTest < ActiveSupport::TestCase
  test "requires the matching value context and honors a thirty day snooze" do
    with_web_push_enabled do
      wrong = Notifications::PromptEligibility.call(
        person: people(:pili), device_token: "pili-tablet", category: "verses", context: "challenge_inbox"
      )
      snoozed = Notifications::PromptEligibility.call(
        person: people(:pili), device_token: "pili-tablet", category: "verses", context: "study_completed"
      )

      refute wrong.eligible
      assert_equal :wrong_context, wrong.reason
      refute snoozed.eligible
      assert_equal :snoozed, snoozed.reason
    end
  end

  test "system denial blocks every automatic category on that device" do
    with_web_push_enabled do
      Notifications::RecordPrompt.call(
        person: people(:pili), device_token: "pili-tablet", category: "challenges",
        result: "system_denied", context: "challenge_inbox"
      )
      result = Notifications::PromptEligibility.call(
        person: people(:pili), device_token: "pili-tablet", category: "verses", context: "study_completed"
      )

      refute result.eligible
      assert_equal :system_denied, result.reason
    end
  end

  test "dismiss records a category-only snooze for thirty days" do
    freeze_time do
      state = Notifications::RecordPrompt.call(
        person: people(:pili), device_token: "pili-tablet", category: "challenges",
        result: "dismissed", context: "challenge_inbox"
      )

      assert_equal 30.days.from_now, state.snoozed_until
      assert_equal "dismissed", state.last_result
    end
  end
end
