class ExpandStreetDuelsForLiveMatches < ActiveRecord::Migration[8.0]
  def change
    add_reference :quiz_runs, :street_duel, foreign_key: true

    change_table :street_duels, bulk: true do |t|
      t.references :challenger_ward, foreign_key: { to_table: :wards }
      t.references :opponent_ward, foreign_key: { to_table: :wards }
      t.string :stake_unit_id
      t.integer :challenger_delta
      t.integer :opponent_delta
    end

    add_index :street_duels, :stake_unit_id
  end
end
