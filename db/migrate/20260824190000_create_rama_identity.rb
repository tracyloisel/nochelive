class CreateRamaIdentity < ActiveRecord::Migration[8.1]
  AVATARS = %w[
    delfin ballena tortuga
    aguila loro colibri
    elefante jirafa cebra
    perro gato oveja
  ].freeze

  def up
    create_table :wards do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.string :presenter_token_digest, null: false
      t.timestamps
    end
    add_index :wards, :code, unique: true

    ward_id = insert_demo_ward!

    add_reference :game_sessions, :ward, foreign_key: true
    execute "UPDATE game_sessions SET ward_id = #{ward_id}"
    change_column_null :game_sessions, :ward_id, false
    add_column :game_sessions, :season_applied_at, :datetime

    create_table :ward_teams do |t|
      t.references :ward, null: false, foreign_key: true
      t.string :name, null: false
      t.string :emblem, null: false
      t.integer :season_xp, null: false, default: 0
      t.string :season_rank_key, null: false, default: "novicio"
      t.timestamps
    end
    add_index :ward_teams, [ :ward_id, :name ], unique: true

    create_table :people do |t|
      t.references :ward, null: false, foreign_key: true
      t.string :given_name, null: false
      t.string :family_name
      t.string :given_name_key, null: false
      t.string :family_name_key, null: false, default: ""
      t.string :avatar_key, null: false
      t.integer :favorite_year, null: false
      t.references :last_ward_team, foreign_key: { to_table: :ward_teams }
      t.timestamps
    end
    add_index :people, [ :ward_id, :given_name_key, :family_name_key, :avatar_key, :favorite_year ],
              unique: true, name: "index_people_on_ficha"

    create_table :person_devices do |t|
      t.references :person, null: false, foreign_key: true
      t.string :device_token, null: false
      t.datetime :last_seen_at
      t.timestamps
    end
    add_index :person_devices, [ :device_token, :person_id ], unique: true
    add_index :person_devices, :device_token

    add_reference :players, :person, foreign_key: true
    add_column :players, :avatar_key, :string
    add_column :players, :device_token, :string
    add_index :players, [ :game_session_id, :person_id ], unique: true, where: "person_id IS NOT NULL"

    AVATARS.each_with_index do |key, index|
      execute "UPDATE players SET avatar_key = #{connection.quote(key)} WHERE (id % 12) = #{index}"
    end
    change_column_null :players, :avatar_key, false

    add_reference :teams, :ward_team, foreign_key: true
    add_column :teams, :season_rank_up, :string
  end

  def down
    remove_column :teams, :season_rank_up
    remove_reference :teams, :ward_team, foreign_key: true
    remove_index :players, name: "index_players_on_game_session_id_and_person_id"
    remove_reference :players, :person, foreign_key: true
    remove_column :players, :avatar_key
    remove_column :players, :device_token
    drop_table :person_devices
    drop_table :people
    drop_table :ward_teams
    remove_column :game_sessions, :season_applied_at
    remove_reference :game_sessions, :ward, foreign_key: true
    drop_table :wards
  end

  private

    def insert_demo_ward!
      now = Time.current
      execute <<~SQL.squish
        INSERT INTO wards (name, code, presenter_token_digest, created_at, updated_at)
        VALUES (
          'Rama DEMO',
          'RAMA',
          #{connection.quote(Digest::SHA256.hexdigest("rama-demo"))},
          #{connection.quote(now)},
          #{connection.quote(now)}
        )
      SQL
      select_value("SELECT id FROM wards WHERE code = 'RAMA'").to_i
    end
end
