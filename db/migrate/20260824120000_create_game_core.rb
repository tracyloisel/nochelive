class CreateGameCore < ActiveRecord::Migration[8.1]
  def change
    create_table :game_sessions do |t|
      t.string :code, null: false
      t.string :status, null: false, default: "lobby"
      t.string :theme_id, null: false
      t.string :theme_title, null: false
      t.string :presenter_token_digest, null: false
      t.timestamps
    end
    add_index :game_sessions, :code, unique: true, where: "status <> 'finished'", name: "index_game_sessions_active_code"
    add_index :game_sessions, :code

    create_table :teams do |t|
      t.references :game_session, null: false, foreign_key: true
      t.string :name, null: false
      t.string :emblem, null: false
      t.integer :cached_score, null: false, default: 0
      t.integer :xp, null: false, default: 0
      t.integer :streak, null: false, default: 0
      t.string :rank_key, null: false, default: "novicio"
      t.boolean :next_correct_doubled, null: false, default: false
      t.timestamps
    end
    add_index :teams, [ :game_session_id, :name ], unique: true

    create_table :players do |t|
      t.references :game_session, null: false, foreign_key: true
      t.string :name, null: false
      t.string :role, null: false, default: "participant"
      t.string :client_token, null: false
      t.timestamps
    end
    add_index :players, [ :game_session_id, :client_token ], unique: true

    create_table :team_memberships do |t|
      t.references :player, null: false, foreign_key: true, index: { unique: true }
      t.references :team, null: false, foreign_key: true
      t.timestamps
    end
    add_index :team_memberships, [ :team_id, :player_id ], unique: true

    create_table :round_runs do |t|
      t.references :game_session, null: false, foreign_key: true
      t.string :yaml_round_id, null: false
      t.integer :position, null: false
      t.string :phase, null: false, default: "pending"
      t.datetime :opened_at
      t.datetime :locked_at
      t.datetime :revealed_at
      t.timestamps
    end
    add_index :round_runs, [ :game_session_id, :position ], unique: true
    add_index :round_runs, [ :game_session_id, :yaml_round_id ], unique: true

    create_table :buzzes do |t|
      t.references :round_run, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.integer :position, null: false
      t.timestamps
    end
    add_index :buzzes, [ :round_run_id, :team_id ], unique: true
    add_index :buzzes, [ :round_run_id, :position ], unique: true

    create_table :answers do |t|
      t.references :round_run, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.string :body, null: false
      t.timestamps
    end
    add_index :answers, [ :round_run_id, :team_id ], unique: true

    create_table :score_events do |t|
      t.references :game_session, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.references :round_run, foreign_key: true
      t.string :kind, null: false
      t.integer :points, null: false, default: 0
      t.integer :xp, null: false, default: 0
      t.string :reason, null: false
      t.timestamps
    end
    add_index :score_events, [ :round_run_id, :team_id, :kind ],
              unique: true,
              where: "round_run_id IS NOT NULL AND kind IN ('correct','fastest_buzz','rapid_tap','participation')",
              name: "index_score_events_unique_round_kind"

    create_table :reward_grants do |t|
      t.references :team, null: false, foreign_key: true
      t.string :chest_key, null: false
      t.string :state, null: false, default: "ready"
      t.string :reward_key
      t.timestamps
    end
    add_index :reward_grants, [ :team_id, :chest_key ], unique: true

    create_table :tap_runs do |t|
      t.references :round_run, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.integer :taps, null: false, default: 0
      t.boolean :finished, null: false, default: false
      t.timestamps
    end
    add_index :tap_runs, [ :round_run_id, :team_id ], unique: true
  end
end
