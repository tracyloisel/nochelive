class NotificationsCleanupJob < ApplicationJob
  queue_as :maintenance

  def perform(now: Time.current)
    NotificationDelivery.where(created_at: ...90.days.ago(now)).delete_all
    WebPushSubscription.where(revoked_at: ...30.days.ago(now)).find_each(&:destroy!)
  end
end
