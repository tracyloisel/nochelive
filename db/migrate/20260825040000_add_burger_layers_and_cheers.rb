class AddBurgerLayersAndCheers < ActiveRecord::Migration[8.1]
  def change
    add_column :round_runs, :layer_index, :integer, default: 0, null: false

    create_table :cheers do |t|
      t.references :round_run, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.references :to_player, null: false, foreign_key: { to_table: :players }
      t.integer :layer_index, null: false
      t.string :mark, null: false, default: "fire"
      t.timestamps
    end
    add_index :cheers, [ :round_run_id, :player_id, :layer_index ], unique: true, name: "index_cheers_on_round_player_layer"
  end
end
