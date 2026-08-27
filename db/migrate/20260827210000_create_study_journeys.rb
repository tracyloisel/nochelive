class CreateStudyJourneys < ActiveRecord::Migration[8.1]
  def change
    create_table :study_programs do |t|
      t.string :slug, null: false
      t.string :title, null: false
      t.integer :year, null: false
      t.string :canon, null: false
      t.string :locale, null: false, default: "fr"
      t.string :status, null: false, default: "draft"
      t.text :source_url, null: false
      t.string :source_digest
      t.datetime :imported_at
      t.timestamps
    end
    add_index :study_programs, :slug, unique: true
    add_index :study_programs, [ :year, :locale ], unique: true

    create_table :study_units do |t|
      t.references :study_program, null: false, foreign_key: true
      t.string :slug, null: false
      t.string :kind, null: false
      t.integer :position, null: false
      t.string :title, null: false
      t.text :source_url, null: false
      t.date :starts_on
      t.date :ends_on
      t.jsonb :scripture_refs, null: false, default: []
      t.jsonb :copy, null: false, default: {}
      t.string :status, null: false, default: "imported"
      t.timestamps
    end
    add_index :study_units, [ :study_program_id, :slug ], unique: true
    add_index :study_units, [ :study_program_id, :kind, :position ], unique: true, name: "index_study_units_on_program_kind_position"
    add_index :study_units, [ :starts_on, :ends_on ]

    create_table :study_quiz_versions do |t|
      t.references :study_unit, null: false, foreign_key: true
      t.integer :version, null: false, default: 1
      t.string :status, null: false, default: "draft"
      t.string :editorial_locale, null: false, default: "fr"
      t.jsonb :content, null: false, default: {}
      t.string :content_digest, null: false
      t.datetime :published_at
      t.timestamps
    end
    add_index :study_quiz_versions, [ :study_unit_id, :version ], unique: true
    add_index :study_quiz_versions, [ :study_unit_id, :status ]

    create_table :study_runs do |t|
      t.references :person, foreign_key: true
      t.references :study_quiz_version, null: false, foreign_key: true
      t.string :device_digest, null: false
      t.string :status, null: false, default: "open"
      t.integer :position, null: false, default: 1
      t.integer :score, null: false, default: 0
      t.datetime :opened_at, null: false
      t.datetime :completed_at
      t.timestamps
    end
    add_index :study_runs, [ :device_digest, :status ]
    add_index :study_runs, [ :person_id, :study_quiz_version_id, :status ], name: "index_study_runs_on_person_quiz_status"

    create_table :study_answers do |t|
      t.references :study_run, null: false, foreign_key: true
      t.string :question_key, null: false
      t.string :choice_key, null: false
      t.boolean :correct, null: false, default: false
      t.integer :duration_ms
      t.timestamps
    end
    add_index :study_answers, [ :study_run_id, :question_key ], unique: true

    create_table :reading_progresses do |t|
      t.references :person, null: false, foreign_key: true
      t.references :study_unit, null: false, foreign_key: true
      t.string :reference, null: false
      t.string :status, null: false, default: "opened"
      t.datetime :completed_at
      t.timestamps
    end
    add_index :reading_progresses, [ :person_id, :study_unit_id, :reference ], unique: true, name: "index_reading_progress_on_person_unit_reference"
  end
end
