class CreateIdentityTransfers < ActiveRecord::Migration[8.1]
  def change
    create_table :identity_transfers do |t|
      t.string :token_digest, null: false
      t.text :encrypted_payload, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end

    add_index :identity_transfers, :token_digest, unique: true
    add_index :identity_transfers, :expires_at
  end
end
