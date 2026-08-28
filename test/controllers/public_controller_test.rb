require "test_helper"

class PublicControllerTest < ActionDispatch::IntegrationTest
  setup do
    @night = game_sessions(:david)
    @round = round_runs(:salomon)
    @round.update!(phase: "open", opened_at: 1.second.ago)
  end

  test "opens anonymously without creating a player" do
    assert_no_difference("Player.count") do
      get night_public_path(@night.public_token)
    end

    assert_response :success
    assert_select "#night_spectator"
    assert_select "form[action='#{night_public_response_path(@night.public_token, @round)}']"
  end

  test "records a public response without affecting the official score" do
    assert_difference("AudienceResponse.count", 1) do
      assert_no_difference("ScoreEvent.count") do
        post night_public_response_path(@night.public_token, @round), params: { choice: "wisdom" }
      end
    end

    assert_redirected_to night_public_path(@night.public_token)
  end

  test "watch remains read only and never creates a spectator player" do
    assert_no_difference("Player.count") do
      get night_watch_path(@night.code)
    end
    assert_response :success
  end
end
