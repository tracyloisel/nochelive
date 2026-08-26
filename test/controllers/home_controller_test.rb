require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "legacy home still serves street reel" do
    get legacy_home_path
    assert_response :success
    assert_select "#street_quiz"
  end
end
