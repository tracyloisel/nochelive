class CreateScriptureCirclePostVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :scripture_circle_post_votes do |t|
      t.references :scripture_circle_post,
        null: false,
        foreign_key: { on_delete: :cascade },
        index: false
      t.references :ward, null: false, foreign_key: { on_delete: :cascade }
      t.references :voter_person,
        null: false,
        foreign_key: { to_table: :people, on_delete: :cascade },
        index: false
      t.string :direction, null: false
      t.timestamps
    end

    add_index :scripture_circle_post_votes,
      [ :scripture_circle_post_id, :voter_person_id ],
      unique: true,
      name: "index_circle_post_votes_unique"
    add_index :scripture_circle_post_votes,
      [ :ward_id, :scripture_circle_post_id ],
      name: "index_circle_post_votes_for_scoring"
    add_index :scripture_circle_post_votes,
      :voter_person_id,
      name: "index_circle_post_votes_on_voter"
    add_check_constraint :scripture_circle_post_votes,
      "direction IN ('up', 'down')",
      name: "scripture_circle_post_votes_direction"
  end
end
