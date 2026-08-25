class CreateQuizRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :quiz_runs do |t|
      t.string :device_digest, null: false
      t.string :pack_id, null: false
      t.integer :position, null: false, default: 1
      t.integer :score, null: false, default: 0
      t.datetime :opened_at, null: false
      t.datetime :ends_at
      t.string :status, null: false, default: "open"
      t.timestamps
    end
    add_index :quiz_runs, :device_digest
    add_index :quiz_runs, [ :device_digest, :status ]

    create_table :quiz_answers do |t|
      t.references :quiz_run, null: false, foreign_key: true
      t.string :device_digest, null: false
      t.string :pack_id, null: false
      t.string :question_id, null: false
      t.string :choice_key
      t.boolean :correct, null: false, default: false
      t.timestamps
    end
    add_index :quiz_answers, [ :quiz_run_id, :question_id ], unique: true
    add_index :quiz_answers, [ :device_digest, :pack_id, :question_id ]
  end
end
