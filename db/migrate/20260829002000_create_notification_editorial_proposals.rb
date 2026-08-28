class CreateNotificationEditorialProposals < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_editorial_proposals do |t|
      t.string :editorial_key, null: false
      t.string :proposal_type, null: false
      t.jsonb :payload, null: false, default: {}
      t.string :status, null: false, default: "draft"
      t.string :approval_token_digest
      t.string :approval_content_digest
      t.datetime :approval_expires_at
      t.datetime :approved_at
      t.timestamps
    end

    add_index :notification_editorial_proposals, :editorial_key, unique: true
    add_index :notification_editorial_proposals, [ :proposal_type, :status ]
  end
end
