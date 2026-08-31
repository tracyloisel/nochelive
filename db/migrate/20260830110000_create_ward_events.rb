class CreateWardEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :ward_events do |t|
      t.references :ward, null: false, foreign_key: { on_delete: :cascade }
      t.string :kind, null: false
      t.string :title, null: false
      t.text :summary, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :location_label, null: false
      t.string :destination_path
      t.string :destination_url
      t.string :artwork_path
      t.string :status, null: false, default: "draft"
      t.string :approved_by
      t.datetime :approved_at
      t.string :cancelled_by
      t.datetime :cancelled_at
      t.string :cancellation_reason
      t.timestamps
    end

    add_index :ward_events, [ :ward_id, :status, :starts_at, :ends_at, :id ],
      name: "index_ward_events_for_hub"
    add_check_constraint :ward_events,
      "kind IN ('clothing_drive', 'toy_drive', 'books_and_school_supplies_drive', 'food_drive', 'sports_activity', 'music_activity', 'art_activity')",
      name: "ward_events_kind"
    add_check_constraint :ward_events,
      "status IN ('draft', 'published', 'cancelled')",
      name: "ward_events_status"
    add_check_constraint :ward_events, "ends_at >= starts_at", name: "ward_events_time_order"
    add_check_constraint :ward_events,
      "(destination_path IS NOT NULL AND destination_url IS NULL) OR (destination_path IS NULL AND destination_url IS NOT NULL)",
      name: "ward_events_one_destination"
    add_check_constraint :ward_events,
      "status <> 'published' OR (approved_by IS NOT NULL AND approved_at IS NOT NULL)",
      name: "ward_events_publication_audit"
    add_check_constraint :ward_events,
      "status <> 'cancelled' OR (cancelled_by IS NOT NULL AND cancelled_at IS NOT NULL AND cancellation_reason IS NOT NULL)",
      name: "ward_events_cancellation_audit"
    add_check_constraint :ward_events, "char_length(title) BETWEEN 1 AND 120", name: "ward_events_title_length"
    add_check_constraint :ward_events, "char_length(summary) BETWEEN 1 AND 280", name: "ward_events_summary_length"
    add_check_constraint :ward_events, "char_length(location_label) BETWEEN 1 AND 120", name: "ward_events_location_length"
    add_check_constraint :ward_events,
      "cancellation_reason IS NULL OR char_length(cancellation_reason) <= 280",
      name: "ward_events_cancellation_reason_length"

    create_table :ward_event_audits do |t|
      t.references :ward_event, null: false, foreign_key: { on_delete: :cascade }
      t.references :ward, null: false, foreign_key: { on_delete: :cascade }
      t.string :action, null: false
      t.string :actor_label, null: false
      t.jsonb :metadata, null: false, default: {}
      t.datetime :created_at, null: false
    end

    add_index :ward_event_audits, [ :ward_event_id, :created_at, :id ], name: "index_ward_event_audits_timeline"
    add_check_constraint :ward_event_audits,
      "action IN ('created', 'updated', 'published', 'cancelled')",
      name: "ward_event_audits_action"
    add_check_constraint :ward_event_audits,
      "char_length(actor_label) BETWEEN 1 AND 120",
      name: "ward_event_audits_actor_length"
  end
end
