require "test_helper"

class People::LinkDeviceTest < ActiveSupport::TestCase
  test "presenter can bind a guest phone to a ficha" do
    night = game_sessions(:elias)
    player = Players::Join.call(
      night:,
      name: "Carmen",
      role: "participant",
      location: "room",
      device_token: "lost-phone",
      avatar_key: "delfin"
    )
    People::LinkDevice.call(night:, player:, person: people(:carmen_garcia))
    assert_equal people(:carmen_garcia), player.reload.person
    assert PersonDevice.exists?(person: people(:carmen_garcia), device_token: "lost-phone")
  end
end
