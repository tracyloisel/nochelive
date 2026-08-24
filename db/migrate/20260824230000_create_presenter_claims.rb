class CreatePresenterClaims < ActiveRecord::Migration[8.1]
  def change
    add_column :game_sessions, :presenter_device_digest, :string

    create_table :presenter_claims do |t|
      t.references :game_session, null: false, foreign_key: true
      t.string :device_digest, null: false
      t.string :name, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :expires_at, null: false
      t.datetime :resolved_at
      t.timestamps
    end
    add_index :presenter_claims, :game_session_id, unique: true, where: "status = 'pending'", name: "index_presenter_claims_one_pending"
    add_index :presenter_claims, [ :game_session_id, :device_digest ]

    create_table :presenter_blocks do |t|
      t.references :game_session, null: false, foreign_key: true
      t.string :device_digest, null: false
      t.timestamps
    end
    add_index :presenter_blocks, [ :game_session_id, :device_digest ], unique: true
  end
end
