class AddStartsAtToGameSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :game_sessions, :starts_at, :datetime
    reversible do |dir|
      dir.up { execute "UPDATE game_sessions SET starts_at = created_at WHERE starts_at IS NULL" }
    end
    change_column_null :game_sessions, :starts_at, false
    add_index :game_sessions, :starts_at
  end
end
