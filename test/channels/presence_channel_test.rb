require "test_helper"

class PresenceChannelTest < ActionCable::Channel::TestCase
  test "street subscription rejects an anonymous connection" do
    subscribe(scope: "street", token: "invalid")

    assert subscription.rejected?
    assert_equal 0, Presences::Registry.live_count
  end

  test "night scope is rejected because Noche state is event-driven" do
    subscribe(scope: "night", token: "unused")
    assert subscription.rejected?
  end
end
