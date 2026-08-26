require "test_helper"

class WardMemoriesControllerTest < ActionDispatch::IntegrationTest
  test "finished night souvenir lives on the rama" do
    get ward_memory_path("RAMA", "QUIT")
    assert_response :success
    assert_select "body.is-paper-hall"
    assert_select "#ward_memory.hall-paper"
    assert_select ".hall-sheet"
    assert_select ".hall-still"
    assert_select "h1", text: /Reyes y Profetas/
    assert_select ".play-reel", count: 0
    assert_select "p.skip", count: 0
  end

  test "live night souvenir sends you to join" do
    get ward_memory_path("RAMA", "DAVID")
    assert_redirected_to night_name_path("DAVID")
  end
end
