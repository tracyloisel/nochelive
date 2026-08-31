class CreateScriptureCircleConversationVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :scripture_circle_conversation_votes do |t|
      t.references :conversation_root,
        null: false,
        foreign_key: { to_table: :scripture_circle_posts, on_delete: :cascade },
        index: false
      t.references :ward, null: false, foreign_key: { on_delete: :cascade }
      t.references :voter_person,
        null: false,
        foreign_key: { to_table: :people, on_delete: :cascade },
        index: false
      t.string :direction, null: false
      t.timestamps
    end

    add_index :scripture_circle_conversation_votes,
      [ :conversation_root_id, :voter_person_id ],
      unique: true,
      name: "index_circle_conversation_votes_unique"
    add_index :scripture_circle_conversation_votes,
      [ :ward_id, :conversation_root_id ],
      name: "index_circle_conversation_votes_for_ranking"
    add_index :scripture_circle_conversation_votes,
      :voter_person_id,
      name: "index_circle_conversation_votes_on_voter"
    add_check_constraint :scripture_circle_conversation_votes,
      "direction IN ('up', 'down')",
      name: "scripture_circle_conversation_votes_direction"
  end
end
