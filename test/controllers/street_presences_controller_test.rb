require "test_helper"

class StreetPresencesControllerTest < ActionDispatch::IntegrationTest
  test "signed-in player can heartbeat" do
    sign_in_congregation
    pili = people(:pili)
    post street_profile_path, params: { person_id: pili.id, favorite_year: pili.favorite_year }
    follow_redirect!
    pili.person_devices.update_all(last_seen_at: 2.minutes.ago)
    assert_not pili.person_devices.merge(PersonDevice.live).exists?

    post street_presence_path
    assert_response :no_content
    assert pili.person_devices.merge(PersonDevice.live).exists?
  end

  test "guest heartbeat is a quiet no-op" do
    post street_presence_path
    assert_response :no_content
  end
end
