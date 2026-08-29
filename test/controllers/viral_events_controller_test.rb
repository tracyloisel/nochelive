require "test_helper"

class ViralEventsControllerTest < ActionDispatch::IntegrationTest
  test "records an attributed share event" do
    invitation = duel_invitations(:open_pili_invitation)
    token = invitation.public_token

    post viral_events_path, params: {
      name: "invite_share_opened",
      duel_token: token,
      source: "ceremony",
      properties: { channel: "native", ignored: "nope" }
    }, as: :json

    assert_response :no_content
    event = ViralEvent.order(:id).last
    assert_equal invitation, event.duel_invitation
    assert_equal "invite_share_opened", event.name
    assert_equal "ceremony", event.source
    assert_equal({ "channel" => "native" }, event.properties)
    assert event.device_digest.present?
  end

  test "does not record an unknown event" do
    assert_no_difference("ViralEvent.count") do
      post viral_events_path, params: { name: "anything_goes" }, as: :json
    end
    assert_response :no_content
  end
end
