class AddLifecycleToStreetDuels < ActiveRecord::Migration[8.1]
  def change
    change_table :street_duels, bulk: true do |t|
      t.references :rematch_of, foreign_key: { to_table: :street_duels }
      t.datetime :delivered_at
      t.datetime :seen_at
      t.datetime :accepted_at
      t.datetime :resolved_at
    end

    add_column :notification_deliveries, :received_at, :datetime
  end
end
