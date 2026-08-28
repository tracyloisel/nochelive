class CreateWebPushNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :web_push_subscriptions do |t|
      t.references :person, null: false, foreign_key: true
      t.string :device_token_digest, null: false
      t.text :endpoint_ciphertext, null: false
      t.string :endpoint_digest, null: false
      t.text :p256dh_ciphertext, null: false
      t.text :auth_ciphertext, null: false
      t.string :locale, null: false, default: "es"
      t.string :time_zone, null: false, default: "UTC"
      t.string :user_agent_family
      t.datetime :last_success_at
      t.datetime :last_failure_at
      t.integer :failure_count, null: false, default: 0
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :web_push_subscriptions, :endpoint_digest, unique: true
    add_index :web_push_subscriptions, [ :person_id, :device_token_digest ], name: "index_push_subscriptions_on_person_device"
    add_index :web_push_subscriptions, :revoked_at

    create_table :notification_preferences do |t|
      t.references :person, null: false, foreign_key: true, index: { unique: true }
      t.boolean :verses_enabled, null: false, default: false
      t.string :verse_frequency, null: false, default: "three_weekly"
      t.time :verse_local_time, null: false, default: "08:00:00"
      t.datetime :verses_enabled_at
      t.boolean :challenges_enabled, null: false, default: false
      t.datetime :challenges_enabled_at
      t.time :quiet_hours_start, null: false, default: "21:00:00"
      t.time :quiet_hours_end, null: false, default: "08:00:00"
      t.timestamps
    end

    create_table :notification_prompt_states do |t|
      t.references :person_device, null: false, foreign_key: true
      t.string :category, null: false
      t.datetime :last_offered_at
      t.string :last_result
      t.datetime :snoozed_until
      t.string :offer_context
      t.timestamps
    end
    add_index :notification_prompt_states, [ :person_device_id, :category ], unique: true, name: "index_notification_prompt_states_on_device_category"
    add_index :notification_prompt_states, :snoozed_until

    create_table :notification_deliveries do |t|
      t.references :web_push_subscription, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :dedupe_key, null: false
      t.references :subject, polymorphic: true
      t.string :destination, null: false
      t.string :status, null: false, default: "queued"
      t.datetime :scheduled_for
      t.datetime :sent_at
      t.datetime :opened_at
      t.datetime :cancelled_at
      t.string :error_code
      t.integer :attempt_count, null: false, default: 0
      t.timestamps
    end
    add_index :notification_deliveries, :dedupe_key, unique: true
    add_index :notification_deliveries, [ :status, :scheduled_for ]
  end
end
