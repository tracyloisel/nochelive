require "test_helper"

class LegacyHomeRouteTest < ActionDispatch::IntegrationTest
  test "legacy home redirects to the hub" do
    get legacy_home_path
    assert_redirected_to "/"
  end
end
