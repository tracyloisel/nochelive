class AddLastSeenAtToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :players, :last_seen_at, :datetime
    add_index :players, :last_seen_at
  end
end
