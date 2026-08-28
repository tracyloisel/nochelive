class CreateViralEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :viral_events do |t|
      t.references :street_duel, foreign_key: true
      t.references :person, foreign_key: true
      t.string :device_digest, null: false
      t.string :name, null: false
      t.string :source
      t.jsonb :properties, null: false, default: {}
      t.timestamps
    end

    add_index :viral_events, [ :name, :created_at ]
    add_index :viral_events, [ :street_duel_id, :name, :created_at ], name: "index_viral_events_on_duel_funnel"
  end
end
