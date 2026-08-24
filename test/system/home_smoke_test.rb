require "application_system_test_case"

class HomeSmokeTest < ApplicationSystemTestCase
  test "home shows the gate" do
    visit root_path
    assert_text "Noche Live"
    assert_button "Entrar"
  end
end
