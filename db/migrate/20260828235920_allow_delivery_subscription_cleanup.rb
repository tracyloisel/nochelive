class AllowDeliverySubscriptionCleanup < ActiveRecord::Migration[8.1]
  def change
    change_column_null :notification_deliveries, :web_push_subscription_id, true
  end
end
