class CreateStreetDuels < ActiveRecord::Migration[8.1]
  def change
    create_table :street_duels do |t|
      t.references :challenger_person, null: false, foreign_key: { to_table: :people }
      t.references :opponent_person, foreign_key: { to_table: :people }
      t.references :ward, null: false, foreign_key: true
      t.string :pack_id, null: false
      t.string :token, null: false
      t.string :status, null: false, default: "pending"
      t.references :challenger_run, foreign_key: { to_table: :quiz_runs }
      t.references :opponent_run, foreign_key: { to_table: :quiz_runs }
      t.integer :challenger_score
      t.integer :opponent_score
      t.datetime :expires_at, null: false
      t.timestamps
    end

    add_index :street_duels, :token, unique: true
    add_index :street_duels, :status
  end
end
