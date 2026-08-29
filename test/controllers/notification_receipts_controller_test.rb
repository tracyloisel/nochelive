require "test_helper"

class NotificationReceiptsControllerTest < ActionDispatch::IntegrationTest
  test "a signed browser receipt marks both delivery and invitation delivered" do
    invitation = duel_invitations(:named_pili_invitation)
    token = invitation.public_token
    delivery = NotificationDelivery.create!(
      web_push_subscription: web_push_subscriptions(:carmen_phone_push),
      person: people(:carmen_garcia), kind: "duel_invitation", subject: invitation,
      dedupe_key: "push-receipt-controller", destination: "/desafio/#{token}", status: "sent"
    )
    receipt_token = delivery.signed_id(purpose: Notifications::AcknowledgeReceipt::PURPOSE, expires_in: 8.days)

    post notifications_receipt_path(token: receipt_token)

    assert_response :no_content
    assert delivery.reload.received?
    assert invitation.reload.delivered_at
  end

  test "rejects a forged receipt token" do
    post notifications_receipt_path(token: "forged")
    assert_response :not_found
  end
end
