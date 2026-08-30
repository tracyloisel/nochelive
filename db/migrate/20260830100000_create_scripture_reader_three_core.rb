class CreateScriptureReaderThreeCore < ActiveRecord::Migration[8.1]
  def change
    create_table :scripture_reader_preferences do |t|
      t.references :person, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.integer :font_scale, null: false, default: 100
      t.string :line_height_key, null: false, default: "comfortable"
      t.string :measure_key, null: false, default: "comfortable"
      t.string :font_family_key, null: false, default: "editorial"
      t.string :background_key, null: false, default: "paper"
      t.boolean :illustrations_enabled, null: false, default: true
      t.timestamps
    end

    add_check_constraint :scripture_reader_preferences,
      "font_scale IN (90, 100, 115, 130, 145)",
      name: "scripture_reader_preferences_font_scale"

    create_table :scripture_reading_progresses do |t|
      t.references :person, null: false, foreign_key: { on_delete: :cascade }
      t.string :reference, null: false
      t.string :locale, null: false
      t.integer :last_verse, null: false, default: 1
      t.integer :last_offset
      t.decimal :progress_ratio, precision: 6, scale: 5, null: false, default: 0
      t.datetime :first_opened_at, null: false
      t.datetime :last_opened_at, null: false
      t.datetime :completed_at
      t.timestamps
    end
    add_index :scripture_reading_progresses, [ :person_id, :reference, :locale ],
      unique: true, name: "index_scripture_progresses_on_person_reference_locale"
    add_check_constraint :scripture_reading_progresses,
      "last_verse > 0 AND progress_ratio >= 0 AND progress_ratio <= 1",
      name: "scripture_reading_progresses_valid_position"

    create_table :scripture_marks do |t|
      t.references :person, null: false, foreign_key: { on_delete: :cascade }
      t.string :reference, null: false
      t.string :locale, null: false
      t.string :anchor_scope, null: false, default: "passage"
      t.integer :start_verse
      t.integer :start_offset
      t.integer :end_verse
      t.integer :end_offset
      t.text :selected_text
      t.string :source_digest
      t.string :visual_style, null: false, default: "none"
      t.string :color_key
      t.datetime :bookmarked_at
      t.string :intent_key
      t.text :note_body
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :scripture_marks, [ :person_id, :reference, :locale, :discarded_at ],
      name: "index_scripture_marks_for_reader"
    add_index :scripture_marks,
      [ :person_id, :reference, :locale, :start_verse, :end_verse, :start_offset, :end_offset ],
      name: "index_scripture_marks_on_person_and_range"
    add_check_constraint :scripture_marks, <<~SQL.squish, name: "scripture_marks_valid_anchor"
      (anchor_scope = 'chapter' AND start_verse IS NULL AND start_offset IS NULL AND end_verse IS NULL AND end_offset IS NULL)
      OR
      (anchor_scope = 'passage' AND start_verse > 0 AND end_verse >= start_verse AND start_offset >= 0 AND end_offset >= 0)
    SQL
    add_check_constraint :scripture_marks,
      "selected_text IS NULL OR char_length(selected_text) <= 10000",
      name: "scripture_marks_selected_text_length"
    add_check_constraint :scripture_marks,
      "note_body IS NULL OR char_length(note_body) <= 5000",
      name: "scripture_marks_note_length"

    create_table :scripture_tags do |t|
      t.references :person, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.string :normalized_name, null: false
      t.timestamps
    end
    add_index :scripture_tags, [ :person_id, :normalized_name ], unique: true

    create_table :scripture_mark_taggings do |t|
      t.references :scripture_mark, null: false, foreign_key: { on_delete: :cascade }
      t.references :scripture_tag, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end
    add_index :scripture_mark_taggings, [ :scripture_mark_id, :scripture_tag_id ],
      unique: true, name: "index_scripture_mark_taggings_unique"

    create_table :scripture_notebooks do |t|
      t.references :person, null: false, foreign_key: { on_delete: :cascade }
      t.string :title, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :scripture_notebooks, [ :person_id, :position ]

    create_table :scripture_notebook_entries do |t|
      t.references :scripture_notebook, null: false, foreign_key: { on_delete: :cascade }
      t.references :scripture_mark, null: false, foreign_key: { on_delete: :cascade }
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :scripture_notebook_entries, [ :scripture_notebook_id, :scripture_mark_id ],
      unique: true, name: "index_scripture_notebook_entries_unique"

    create_table :scripture_mark_links do |t|
      t.references :scripture_mark, null: false, foreign_key: { on_delete: :cascade }
      t.string :target_reference, null: false
      t.string :target_locale, null: false
      t.integer :target_start_verse
      t.integer :target_start_offset
      t.integer :target_end_verse
      t.integer :target_end_offset
      t.text :target_text
      t.timestamps
    end
    add_index :scripture_mark_links, [ :scripture_mark_id, :target_reference, :target_locale ],
      name: "index_scripture_mark_links_on_target"

    create_table :scripture_chapter_guides do |t|
      t.string :reference, null: false
      t.string :locale, null: false
      t.string :welcome_title, null: false
      t.text :summary, null: false
      t.string :theme_key
      t.jsonb :source_citations, null: false, default: []
      t.string :status, null: false, default: "draft"
      t.integer :revision, null: false, default: 1
      t.string :reviewed_by
      t.datetime :published_at
      t.timestamps
    end
    add_index :scripture_chapter_guides, [ :reference, :locale, :revision ], unique: true,
      name: "index_scripture_guides_on_reference_locale_revision"
    add_index :scripture_chapter_guides, [ :reference, :locale ], unique: true,
      where: "status = 'published'", name: "index_scripture_guides_one_published"

    create_table :scripture_video_links do |t|
      t.string :reference, null: false
      t.string :locale, null: false
      t.string :youtube_video_id, null: false
      t.string :channel_id, null: false
      t.integer :anchor_verse
      t.text :editorial_reason, null: false
      t.integer :position, null: false, default: 0
      t.string :status, null: false, default: "draft"
      t.datetime :verified_at
      t.timestamps
    end
    add_index :scripture_video_links, [ :reference, :locale, :youtube_video_id ], unique: true,
      name: "index_scripture_video_links_unique"
    add_index :scripture_video_links, [ :reference, :locale, :status, :position ],
      name: "index_scripture_video_links_for_reader"

    add_reference :scripture_chapter_reads, :ward, foreign_key: { on_delete: :nullify }
    add_column :wards, :scripture_circle_mode, :string, null: false, default: "disabled"
    add_check_constraint :wards,
      "scripture_circle_mode IN ('disabled', 'read_only', 'active')",
      name: "wards_scripture_circle_mode"
  end
end
