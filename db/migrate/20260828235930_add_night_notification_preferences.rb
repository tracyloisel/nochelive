class AddNightNotificationPreferences < ActiveRecord::Migration[8.1]
  def change
    add_column :notification_preferences, :nights_enabled, :boolean, null: false, default: false
    add_column :notification_preferences, :nights_enabled_at, :datetime
  end
end
