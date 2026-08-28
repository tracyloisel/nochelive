class CreateScriptureHighlights < ActiveRecord::Migration[8.1]
  def change
    create_table :scripture_highlights do |t|
      t.references :person, null: false, foreign_key: { on_delete: :cascade }
      t.string :reference, null: false
      t.string :locale, null: false
      t.integer :start_verse, null: false
      t.integer :end_verse, null: false
      t.integer :start_offset, null: false
      t.integer :end_offset, null: false
      t.timestamps
    end

    add_index :scripture_highlights,
      [ :person_id, :reference, :locale, :start_verse, :end_verse, :start_offset, :end_offset ],
      unique: true,
      name: "index_scripture_highlights_on_person_and_range"
    add_index :scripture_highlights, [ :reference, :locale ]
    add_check_constraint :scripture_highlights,
      "start_verse > 0 AND end_verse >= start_verse AND start_offset >= 0 AND end_offset >= 0",
      name: "scripture_highlights_valid_range"
  end
end
