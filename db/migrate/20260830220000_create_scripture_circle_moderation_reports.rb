class CreateScriptureCircleModerationReports < ActiveRecord::Migration[8.0]
  def change
    create_table :scripture_circle_moderation_reports do |t|
      t.references :scripture_circle_post, null: false,
        foreign_key: { on_delete: :cascade },
        index: { name: "index_scripture_circle_reports_on_post_id" }
      t.references :ward, null: false, foreign_key: { on_delete: :cascade }
      t.references :reporter_person, null: false,
        foreign_key: { to_table: :people, on_delete: :cascade },
        index: { name: "index_scripture_circle_reports_on_reporter_id" }
      t.string :reason_key, null: false
      t.string :reason_details
      t.timestamps
    end

    add_index :scripture_circle_moderation_reports,
      [ :scripture_circle_post_id, :reporter_person_id ],
      unique: true,
      name: "index_scripture_circle_reports_unique"
    add_index :scripture_circle_moderation_reports,
      [ :ward_id, :scripture_circle_post_id ],
      name: "index_scripture_circle_reports_on_ward_and_post"
    add_check_constraint :scripture_circle_moderation_reports,
      "reason_details IS NULL OR char_length(reason_details) <= 240",
      name: "scripture_circle_reports_reason_length"
  end
end
