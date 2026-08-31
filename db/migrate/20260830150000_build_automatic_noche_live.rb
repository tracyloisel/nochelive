class BuildAutomaticNocheLive < ActiveRecord::Migration[8.0]
  def change
    add_column :game_sessions, :ends_at, :datetime
    add_column :game_sessions, :closed_at, :datetime
    add_column :game_sessions, :cancelled_at, :datetime

    reversible do |direction|
      direction.up do
        execute <<~SQL.squish
          UPDATE game_sessions
          SET ends_at = starts_at + INTERVAL '1 hour'
          WHERE ends_at IS NULL
        SQL
      end
    end

    change_column_null :game_sessions, :ends_at, false
    add_index :game_sessions, [ :status, :starts_at, :ends_at ], name: "index_nights_on_lifecycle"
    remove_index :game_sessions, name: "index_game_sessions_active_code"
    add_index :game_sessions,
      :code,
      unique: true,
      where: "status NOT IN ('finished', 'cancelled')",
      name: "index_game_sessions_active_code"

    add_reference :quiz_runs, :game_session, foreign_key: true
    add_reference :quiz_runs, :player, foreign_key: true
    add_reference :quiz_runs, :team, foreign_key: true
    add_column :quiz_runs, :live_sequence_position, :integer
    add_column :quiz_runs, :expired_at, :datetime
    add_index :quiz_runs,
      [ :game_session_id, :player_id, :live_sequence_position ],
      unique: true,
      where: "game_session_id IS NOT NULL",
      name: "index_quiz_runs_on_live_sequence"
    add_index :quiz_runs, [ :game_session_id, :status ], name: "index_quiz_runs_on_night_status"
    add_index :quiz_runs, [ :game_session_id, :team_id ], name: "index_quiz_runs_on_night_team"

    create_table :live_events do |t|
      t.references :game_session, null: false, foreign_key: true
      t.string :kind, null: false
      t.jsonb :payload, null: false, default: {}
      t.string :dedupe_key, null: false
      t.datetime :occurred_at, null: false
      t.timestamps
    end
    add_index :live_events, [ :game_session_id, :dedupe_key ], unique: true
    add_index :live_events, [ :game_session_id, :occurred_at, :id ], name: "index_live_events_on_timeline"
  end
end
