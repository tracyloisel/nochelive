require "test_helper"

class NotificationPreferenceTest < ActiveSupport::TestCase
  test "enables each category without implying consent to the other" do
    preference = notification_preferences(:pili_notifications)

    preference.enable!("challenges")
    assert preference.challenges_enabled?
    refute preference.verses_enabled?

    preference.enable!("verses")
    assert preference.reload.verses_enabled?
    assert preference.challenges_enabled?
  end
end
