require "test_helper"

class StreetGuestsControllerTest < ActionDispatch::IntegrationTest
  test "unknown city can continue on the hub without inventing a rama" do
    post street_guest_path

    assert_redirected_to root_path
    assert_equal I18n.t("flashes.street_guest_ready"), flash[:notice]
    follow_redirect!
    assert_select ".banner", text: I18n.t("flashes.street_guest_ready")
  end
end
