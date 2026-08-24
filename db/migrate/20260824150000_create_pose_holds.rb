class CreatePoseHolds < ActiveRecord::Migration[8.1]
  def change
    create_table :pose_holds do |t|
      t.references :round_run, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.integer :held_ms, null: false, default: 0
      t.boolean :finished, null: false, default: false
      t.timestamps
    end
    add_index :pose_holds, [ :round_run_id, :team_id ], unique: true
  end
end
