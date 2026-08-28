require "test_helper"

class NotificationsCleanupJobTest < ActiveJob::TestCase
  test "deletes revoked endpoints after thirty days and delivery logs after ninety" do
    subscription = web_push_subscriptions(:carmen_phone_push)
    delivery = notification_deliveries(:carmen_duel_result)
    subscription.update!(revoked_at: 31.days.ago)
    delivery.update_columns(created_at: 40.days.ago, updated_at: 40.days.ago)
    expired_log = NotificationDelivery.create!(
      web_push_subscription: web_push_subscriptions(:pili_tablet_push),
      person: people(:pili), kind: "study_reading",
      dedupe_key: "expired-delivery-log", destination: "/parole",
      status: "sent", sent_at: 91.days.ago, created_at: 91.days.ago, updated_at: 91.days.ago
    )

    NotificationsCleanupJob.perform_now(now: Time.current)

    assert_not WebPushSubscription.exists?(subscription.id)
    assert NotificationDelivery.exists?(delivery.id)
    assert_nil delivery.reload.web_push_subscription_id
    assert_not NotificationDelivery.exists?(expired_log.id)
  end
end
