require "test_helper"

class PresencesControllerTest < ActionDispatch::IntegrationTest
  setup { @night = game_sessions(:david) }

  test "signed-in player can heartbeat" do
    sign_in_as_participant(@night, name: "Sofía", team: teams(:leones))
    post night_presence_path(@night.code)
    assert_response :no_content
    player = @night.players.find_by!(name: "Sofía")
    assert player.live?
  end

  test "guest cannot heartbeat" do
    post night_presence_path(@night.code)
    assert_redirected_to night_name_path(@night.code)
  end
end
