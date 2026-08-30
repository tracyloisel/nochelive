class CreateScriptureCircle < ActiveRecord::Migration[8.1]
  def change
    create_table :scripture_circle_threads do |t|
      t.references :ward, null: false, foreign_key: { on_delete: :cascade }
      t.string :reference, null: false
      t.string :status, null: false, default: "active"
      t.timestamps
    end
    add_index :scripture_circle_threads, [ :ward_id, :reference ], unique: true

    create_table :scripture_circle_posts do |t|
      t.references :scripture_circle_thread, null: false, foreign_key: { on_delete: :cascade },
        index: { name: "index_scripture_circle_posts_on_thread_id" }
      t.references :ward, null: false, foreign_key: { on_delete: :cascade }
      t.references :person, foreign_key: { on_delete: :nullify }
      t.references :parent, foreign_key: { to_table: :scripture_circle_posts, on_delete: :nullify }
      t.string :kind, null: false
      t.string :locale, null: false
      t.text :body, null: false
      t.integer :start_verse
      t.integer :end_verse
      t.text :selected_text
      t.string :status, null: false, default: "visible"
      t.datetime :edited_at
      t.datetime :deleted_at
      t.timestamps
    end
    add_index :scripture_circle_posts, [ :person_id, :created_at ], order: { created_at: :desc },
      name: "index_scripture_circle_posts_for_profile"
    add_index :scripture_circle_posts, [ :ward_id, :status, :created_at ],
      name: "index_scripture_circle_posts_for_ward"
    add_check_constraint :scripture_circle_posts,
      "char_length(body) BETWEEN 1 AND 500",
      name: "scripture_circle_posts_body_length"
    add_check_constraint :scripture_circle_posts,
      "selected_text IS NULL OR char_length(selected_text) <= 1000",
      name: "scripture_circle_posts_selected_text_length"

    create_table :scripture_circle_post_revisions do |t|
      t.references :scripture_circle_post, null: false, foreign_key: { on_delete: :cascade },
        index: { name: "index_scripture_circle_revisions_on_post_id" }
      t.references :editor_person, foreign_key: { to_table: :people, on_delete: :nullify }
      t.references :ward, null: false, foreign_key: { on_delete: :cascade }
      t.integer :revision_number, null: false
      t.text :body, null: false
      t.integer :start_verse
      t.integer :end_verse
      t.string :change_kind, null: false
      t.string :content_digest, null: false
      t.datetime :created_at, null: false
    end
    add_index :scripture_circle_post_revisions,
      [ :scripture_circle_post_id, :revision_number ], unique: true,
      name: "index_scripture_circle_revisions_unique"
    add_check_constraint :scripture_circle_post_revisions,
      "char_length(body) BETWEEN 1 AND 500",
      name: "scripture_circle_revisions_body_length"

    create_table :scripture_circle_moderation_proposals do |t|
      t.references :scripture_circle_post, null: false, foreign_key: { on_delete: :cascade },
        index: { name: "index_scripture_circle_proposals_on_post_id" }
      t.references :ward, null: false, foreign_key: { on_delete: :cascade }
      t.references :proposer_person, foreign_key: { to_table: :people, on_delete: :nullify }
      t.references :post_revision, null: false,
        foreign_key: { to_table: :scripture_circle_post_revisions, on_delete: :restrict }
      t.string :reason_key, null: false
      t.string :reason_details
      t.string :status, null: false, default: "open"
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.datetime :resolved_at
      t.integer :yes_count, null: false, default: 0
      t.integer :no_count, null: false, default: 0
      t.integer :valid_ballot_count, null: false, default: 0
      t.string :policy_version, null: false
      t.string :result_digest
      t.timestamps
    end
    add_index :scripture_circle_moderation_proposals, :scripture_circle_post_id,
      unique: true, where: "status = 'open'", name: "index_scripture_circle_one_open_proposal"
    add_index :scripture_circle_moderation_proposals, [ :status, :ends_at ],
      name: "index_scripture_circle_due_proposals"
    add_check_constraint :scripture_circle_moderation_proposals,
      "ends_at >= starts_at + interval '2 days'",
      name: "scripture_circle_proposals_minimum_duration"
    add_check_constraint :scripture_circle_moderation_proposals,
      "yes_count >= 0 AND no_count >= 0 AND valid_ballot_count >= 0",
      name: "scripture_circle_proposals_nonnegative_counts"
    add_check_constraint :scripture_circle_moderation_proposals,
      "reason_details IS NULL OR char_length(reason_details) <= 240",
      name: "scripture_circle_proposals_reason_length"

    create_table :scripture_circle_moderation_ballots do |t|
      t.references :scripture_circle_moderation_proposal, null: false,
        foreign_key: { on_delete: :cascade }, index: { name: "index_scripture_circle_ballots_on_proposal_id" }
      t.references :ward, null: false, foreign_key: { on_delete: :cascade }
      t.references :voter_person, foreign_key: { to_table: :people, on_delete: :nullify }
      t.string :choice, null: false
      t.datetime :cast_at, null: false
      t.timestamps
    end
    add_index :scripture_circle_moderation_ballots,
      [ :scripture_circle_moderation_proposal_id, :voter_person_id ], unique: true,
      name: "index_scripture_circle_ballots_unique"

    create_table :scripture_circle_moderation_ballot_revisions do |t|
      t.references :scripture_circle_moderation_ballot, null: false,
        foreign_key: { on_delete: :cascade }, index: { name: "index_scripture_circle_ballot_revisions_on_ballot" }
      t.references :proposal, null: false,
        foreign_key: { to_table: :scripture_circle_moderation_proposals, on_delete: :cascade }
      t.references :ward, null: false, foreign_key: { on_delete: :cascade }
      t.references :voter_person, foreign_key: { to_table: :people, on_delete: :nullify }
      t.string :previous_choice
      t.string :new_choice, null: false
      t.datetime :created_at, null: false
    end

    create_table :scripture_circle_moderation_events do |t|
      t.references :proposal, null: false,
        foreign_key: { to_table: :scripture_circle_moderation_proposals, on_delete: :cascade }
      t.references :post, null: false,
        foreign_key: { to_table: :scripture_circle_posts, on_delete: :cascade }
      t.references :ward, null: false, foreign_key: { on_delete: :cascade }
      t.references :actor_person, foreign_key: { to_table: :people, on_delete: :nullify }
      t.string :event_type, null: false
      t.jsonb :metadata, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index :scripture_circle_moderation_events, [ :proposal_id, :created_at ],
      name: "index_scripture_circle_events_timeline"
  end
end
