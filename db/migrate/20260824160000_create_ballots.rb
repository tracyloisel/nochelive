class CreateBallots < ActiveRecord::Migration[8.1]
  def change
    create_table :ballots do |t|
      t.references :round_run, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.references :choice_team, null: false, foreign_key: { to_table: :teams }
      t.timestamps
    end
    add_index :ballots, [ :round_run_id, :player_id ], unique: true
  end
end
