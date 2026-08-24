require "test_helper"

class PresenterBlockTest < ActiveSupport::TestCase
  test "one block per phone per night" do
    night = game_sessions(:david)
    digest = GameSession.digest_token("nuisance")
    PresenterBlock.create!(game_session: night, device_digest: digest)
    dup = PresenterBlock.new(game_session: night, device_digest: digest)
    assert_not dup.valid?
  end
end
