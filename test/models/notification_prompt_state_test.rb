require "test_helper"

class NotificationPromptStateTest < ActiveSupport::TestCase
  test "snooze is scoped to one device and category" do
    state = notification_prompt_states(:pili_verses_snoozed)

    assert state.snoozed?
    refute NotificationPromptState.exists?(person_device: state.person_device, category: "challenges")
    refute NotificationPromptState.exists?(person_device: state.person_device, category: "nights")
  end

  test "rejects unknown categories and contexts" do
    state = NotificationPromptState.new(person_device: person_devices(:pili_tablet), category: "marketing", offer_context: "signup")

    refute state.valid?
    assert state.errors[:category].any?
    assert state.errors[:offer_context].any?
  end
end
