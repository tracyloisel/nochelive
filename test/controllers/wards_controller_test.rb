require "test_helper"

class WardsControllerTest < ActionDispatch::IntegrationTest
  test "create a rama then a night" do
    get new_ward_path
    assert_response :success

    assert_difference -> { Ward.count }, 1 do
      post wards_path, params: { name: "Madrid Centro" }
    end
    follow_redirect!
    assert_response :success

    assert_difference -> { GameSession.count }, 1 do
      post game_sessions_path
    end
  end
end
