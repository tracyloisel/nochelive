require "test_helper"

class NotificationPreferenceTest < ActiveSupport::TestCase
  test "enables each category without implying consent to the other" do
    preference = notification_preferences(:pili_notifications)

    preference.enable!("challenges")
    assert preference.challenges_enabled?
    refute preference.verses_enabled?
    refute preference.nights_enabled?

    preference.enable!("nights")
    assert preference.reload.nights_enabled?
    assert preference.challenges_enabled?
    refute preference.verses_enabled?

    preference.enable!("verses")
    assert preference.reload.verses_enabled?
    assert preference.challenges_enabled?
    assert preference.nights_enabled?
  end
end
