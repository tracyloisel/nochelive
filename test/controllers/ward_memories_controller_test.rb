require "test_helper"

class WardMemoriesControllerTest < ActionDispatch::IntegrationTest
  test "finished night souvenir lives on the rama" do
    get ward_memory_path("RAMA", "QUIT")
    assert_response :success
    assert_select "h1", text: /Reyes y Profetas/
  end

  test "live night souvenir sends you to join" do
    get ward_memory_path("RAMA", "DAVID")
    assert_redirected_to night_name_path("DAVID")
  end
end
