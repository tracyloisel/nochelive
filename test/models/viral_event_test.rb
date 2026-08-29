require "test_helper"

class ViralEventTest < ActiveSupport::TestCase
  test "keeps an anonymous funnel event when its profile is deleted" do
    person = people(:carmen_lopez)
    event = ViralEvent.create!(
      name: "invitee_profile_created",
      device_digest: "deleted-profile-device",
      person:,
      source: "invite"
    )

    person.destroy!

    assert_nil event.reload.person
    assert_equal "invitee_profile_created", event.name
  end
end
