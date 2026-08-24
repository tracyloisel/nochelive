require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "home and health" do
    get root_path
    assert_response :success
    get "/up"
    assert_response :success
  end
end
