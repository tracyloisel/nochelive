class CreateAudienceInteractions < ActiveRecord::Migration[8.1]
  def up
    add_column :game_sessions, :public_token, :string
    add_column :game_sessions, :broadcast_delay_ms, :integer, default: 0, null: false

    execute <<~SQL
      UPDATE game_sessions
      SET public_token = md5(random()::text || clock_timestamp()::text || id::text)
      WHERE public_token IS NULL
    SQL

    change_column_null :game_sessions, :public_token, false
    add_index :game_sessions, :public_token, unique: true

    create_table :audience_responses do |t|
      t.references :round_run, null: false, foreign_key: true
      t.string :audience_digest, null: false
      t.string :choice, null: false
      t.datetime :answered_at, null: false
      t.timestamps
    end
    add_index :audience_responses, [ :round_run_id, :audience_digest ], unique: true

    create_table :audience_reactions do |t|
      t.references :round_run, null: false, foreign_key: true
      t.string :audience_digest, null: false
      t.string :mark, null: false
      t.timestamps
    end
    add_index :audience_reactions, [ :round_run_id, :audience_digest, :created_at ],
      name: "index_audience_reactions_on_round_audience_time"
  end

  def down
    drop_table :audience_reactions
    drop_table :audience_responses
    remove_index :game_sessions, :public_token
    remove_column :game_sessions, :broadcast_delay_ms
    remove_column :game_sessions, :public_token
  end
end
