require "test_helper"

class Notifications::PromptEligibilityTest < ActiveSupport::TestCase
  test "requires the matching value context and honors a thirty day snooze" do
    with_web_push_enabled do
      wrong = Notifications::PromptEligibility.call(
        person: people(:pili), device_token: "pili-tablet", category: "verses", context: "duel_campus"
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
        result: "system_denied", context: "duel_campus"
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
        result: "dismissed", context: "duel_campus"
      )

      assert_equal 30.days.from_now, state.snoozed_until
      assert_equal "dismissed", state.last_result
    end
  end

  test "an active category is suppressed only on a currently subscribed device" do
    with_web_push_enabled do
      person = people(:pili)
      person.notification_preference.enable!(:challenges)

      subscribed = Notifications::PromptEligibility.call(
        person:, device_token: "pili-tablet", category: "challenges", context: "duel_campus"
      )

      person.person_devices.create!(device_token: "pili-phone", last_seen_at: Time.current)
      other_device = Notifications::PromptEligibility.call(
        person:, device_token: "pili-phone", category: "challenges", context: "duel_campus"
      )

      refute subscribed.eligible
      assert_equal :already_active, subscribed.reason
      assert other_device.eligible
      assert_equal :eligible, other_device.reason
    end
  end
end
